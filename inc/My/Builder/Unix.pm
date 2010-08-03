package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Spec qw(devnull);
use File::Glob qw(glob);
use File::Copy;
use Config;

sub build_binaries {
  my ($self, $build_out, $srcdir) = @_;

  my ($extra_cflags, $extra_lflags) = ('-I/usr/local/include', '-L/usr/local/lib');
  if (-d '/usr/X11R6/include' && -d '/usr/X11R6/lib' ) {
    $extra_cflags .= ' -I/usr/X11R6/include';
    $extra_lflags .= ' -L/usr/X11R6/lib';
  }

  print "Checking available libraries/headers...\n";
  my %has;

  $has{gtk}     = `pkg-config --modversion gtk+-2.0 2>/dev/null` ? 1 : 0;        #iupgtk
  $has{gtkx11}  = `pkg-config --modversion gtk+-x11-2.0 2>/dev/null` ? 1 : 0;
  $has{gdk}     = `pkg-config --modversion gdk-2.0 2>/dev/null` ? 1 : 0;        #cdgdk
  $has{gdkx11}  = `pkg-config --modversion gdk-x11-2.0 2>/dev/null` ? 1 : 0;
  $has{cairo}   = `pkg-config --modversion cairo 2>/dev/null` ? 1 : 0;                 #cdcairo
  $has{pango}   = `pkg-config --modversion pango 2>/dev/null` ? 1 : 0;                #cdcairo
  $has{pangox}  = `pkg-config --modversion pangox 2>/dev/null` ? 1 : 0;

  $has{l_gtk}   = $has{gtk}    && $self->check_lib( [] , `pkg-config --cflags gtk+-2.0 2>/dev/null`,     `pkg-config --libs gtk+-2.0 2>/dev/null`);
  $has{l_gtkx11}= $has{gtkx11} && $self->check_lib( [] , `pkg-config --cflags gtk+-x11-2.0 2>/dev/null`, `pkg-config --libs gtk+-x11-2.0 2>/dev/null`);
  $has{l_gdk}   = $has{gdk}    && $self->check_lib( [] , `pkg-config --cflags gdk-2.0 2>/dev/null`,      `pkg-config --libs gdk-2.0 2>/dev/null`);
  $has{l_gdkx11}= $has{gdkx11} && $self->check_lib( [] , `pkg-config --cflags gdk-x11-2.0 2>/dev/null`,  `pkg-config --libs gdk-x11-2.0 2>/dev/null`);
  $has{l_cairo} = $has{cairo}  && $self->check_lib( [] , `pkg-config --cflags cairo 2>/dev/null`,        `pkg-config --libs cairo 2>/dev/null`);
  $has{l_pango} = $has{pango}  && $self->check_lib( [] , `pkg-config --cflags pango 2>/dev/null`,        `pkg-config --libs pango 2>/dev/null`);
  $has{l_pangox}= $has{pangox} && $self->check_lib( [] , `pkg-config --cflags pangox 2>/dev/null`,       `pkg-config --libs pangox 2>/dev/null`);

  $has{l_Xp}    = $self->check_lib( 'Xp',   $extra_cflags, $extra_lflags );
  $has{l_Xt}    = $self->check_lib( 'Xt',   $extra_cflags, $extra_lflags );
  $has{l_Xm}    = $self->check_lib( 'Xm',   $extra_cflags, $extra_lflags );
  $has{l_Xmu}   = $self->check_lib( 'Xmu',  $extra_cflags, $extra_lflags );
  $has{l_Xext}  = $self->check_lib( 'Xext', $extra_cflags, $extra_lflags );
  $has{l_X11}   = $self->check_lib( 'X11',  $extra_cflags, $extra_lflags );
  $has{l_GL}    = $self->check_lib( 'GL',   $extra_cflags, $extra_lflags );
  $has{l_GLU}   = $self->check_lib( 'GLU',  $extra_cflags, $extra_lflags );
  $has{l_glut}  = $self->check_lib( 'glut', $extra_cflags, $extra_lflags );
  $has{l_gdi32} = $self->check_lib( 'gdi32' );  # cygwin only
  $has{l_glu32} = $self->check_lib( 'glu32' );  # cygwin only

  $has{Xm}      = $self->check_header('Xm/Xm.h',   $extra_cflags);
  $has{Xlib}    = $self->check_header('X11/Xlib.h',$extra_cflags);        #iupgl cdx11
  $has{glx}     = $self->check_header('GL/glx.h',  $extra_cflags);             #iupgl
  $has{glu}     = $self->check_header('GL/glu.h',  $extra_cflags);
  $has{gl}      = $self->check_header('GL/gl.h',   $extra_cflags);
  $has{fftw3}   = $self->check_header('fftw3.h',   $extra_cflags);        #im_fftw3 = http://www.fftw.org/
  $has{windows} = $self->check_header('windows.h');                #iupwin
  $has{wmsdk}   = $self->check_header('wmsdk.h');                #im_wmv
  $has{ecw}     = $self->check_header('NCSECWClient.h');        #im_format_ecw = ECW (Enhanced Compression Wavelet) format
  $has{XxXxX}   = $self->check_header('XxXxX/XxXxX.h');           #non existing header

  print "Has: $has{$_} - $_\n" foreach (sort keys %has);

  my @x11_libs; # just base X11 libs
  push(@x11_libs, 'X11')  if $has{l_X11};
  push(@x11_libs, 'Xext') if $has{l_Xext};

  my @opengl_libs; # for non MS Windows
  push(@opengl_libs, 'GL')  if $has{l_GL};
  push(@opengl_libs, 'GLU') if $has{l_GLU};

  #possible targets: im im_process im_jp2 im_fftw im_capture im_avi im_wmv im_fftw3 im_ecw
  my @imtargets = qw[im im_process im_jp2 im_fftw];

  #possible targets: cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl cdcontextplus cdcairo
  my @cdtargets = qw[cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl];
  @cdtargets = grep { $_ !~ /^(cd_ftgl|cdgl)$/ } @cdtargets unless $has{l_GLU};

  #possible targets: iup iupcd iupcontrols iupim iupimglib iup_pplot iupgl
  my @iuptargets = qw[iup iupcd iupcontrols iupim iupimglib iup_pplot iupgl];
  @iuptargets = grep { $_ !~ /^(iupgl)$/ } @cdtargets unless ($has{windows} && $has{gl}) || ($has{glx});

  #store debug info into ConfigData
  $self->config_data('debug_has', \%has);
  $self->config_data('debug_imtargets', \@imtargets);
  $self->config_data('debug_cdtargets', \@cdtargets);
  $self->config_data('debug_iuptargets', \@iuptargets);

  #my @makeopts  = qw[NO_DYNAMIC=Yes USE_NODEPEND=Yes];
  my @makeopts  = qw[NO_STATIC=Yes USE_NODEPEND=Yes];

  #choose GUI subsystem, priorities if multiple subsystems detected: 1. Win32(cygwin), 2. GTK, 3. X11/Motif
  my @libs;
  if ($has{windows}) { #cygwin only
    push(@makeopts, 'USE_WIN=Yes');
    push(@makeopts, 'X11_LIBS='); #no X11 libs on cygwin
    push(@libs, qw[gdi32 comdlg32 comctl32 winspool uuid ole32 oleaut32 opengl32 glu32 glut]);
    ($extra_cflags, $extra_lflags) = ('', '');
  }
  elsif ($has{gtk}) {
    push(@makeopts, 'USE_GTK=Yes');
    push(@makeopts, "X11_LIBS=" . join(' ', @x11_libs));
    push(@makeopts, "OPENGL_LIBS=" . join(' ', @opengl_libs));
    my $mods = 'gtk+-2.0 gdk-2.0 pango cairo';
    push(@libs, @opengl_libs);
    #Note: $extra_?flags will be stored into ConfigData - they are not used for building
    ($extra_cflags = `pkg-config --cflags $mods 2>/dev/null`) =~ s/[\n\r]*$//;
    ($extra_lflags = `pkg-config --libs $mods 2>/dev/null`) =~ s/[\n\r]*$//;
  }
  elsif ($has{Xlib} && $has{Xm}) {
    push(@makeopts, 'USE_X11=Yes');
    # additional X11 related libs
    push(@x11_libs, 'Xp')   if $has{l_Xp};
    push(@x11_libs, 'Xt')   if $has{l_Xt};
    push(@x11_libs, 'Xm')   if $has{l_Xm};
    push(@x11_libs, 'Xmu')  if $has{l_Xmu};
    push(@makeopts, "X11_LIBS=" . join(' ', @x11_libs));
    push(@makeopts, "OPENGL_LIBS=" . join(' ', @opengl_libs));
    push(@libs, @x11_libs, @opengl_libs);
    #Note: $extra_?flags set at the beginning of this sub
  }
  else {
    warn "###WARN### No supported GUI subsystem (Win32, GTK, X11/Motif) detected!";
  }

  #do the job
  print "Gonna make these targets: " . join(' ', @iuptargets, @cdtargets, @imtargets) . "\n";
  $self->build_via_tecmake($build_out, $srcdir, \@makeopts, \@iuptargets, \@cdtargets, \@imtargets);

  #make a list of libs necessary to link with IUP and related libraries
  my %seen;
  foreach (glob("$build_out/lib/*")) {
    $seen{$1} = 1 if ($_ =~ /lib([a-zA-Z0-9\_\-\.]*?)\.(so|dylib|bundle|a|dll\.a)$/);
  }
  print "Output lib: $_\n" foreach (sort keys %seen);
  @libs = ( sort keys %seen, @libs );

  $self->config_data('linker_libs', \@libs);
  $self->config_data('extra_cflags', $extra_cflags);
  $self->config_data('extra_lflags', $extra_lflags);
};

sub build_via_tecmake {
  my ($self, $build_out, $srcdir, $mopts, $iuptgs, $cdtgs, $imtgs) = @_;
  $srcdir ||= 'src';
  my $prefixdir   = rel2abs($build_out);
  my $make        = $self->get_make;
  my @makeopts    = @{$mopts};
  my $makesysinfo = "$make -f tecmake.mak sysinfo MAKENAME= USE_NODEPEND=Yes '" . join("' '", @makeopts) .  "'";
  my ($im_si, $cd_si, $iup_si);

  # save it for future use in ConfigData
  $self->config_data('build_prefix', $prefixdir);
  $self->config_data('debug_makeopts', \@makeopts);

  #create output directory structure
  mkdir "$prefixdir" unless -d "$prefixdir";
  mkdir "$prefixdir/lib" unless -d "$prefixdir/lib";
  mkdir "$prefixdir/include" unless -d "$prefixdir/include";

  my %done;

  if(-d "$srcdir/im/src") {
    print "Gonna build 'im'\n";
    chdir "$srcdir/im/src";
    ($im_si =`$makesysinfo 2>&1`) =~ s/[\n\r]*$//;
    print "$im_si\n";
    foreach my $t (@{$imtgs}) {
      $done{$t} = $self->do_system_output_tail(1000, $make, $t, @makeopts);
      warn "###WARN### [$?] during make $t" unless $done{$t};
    }
    copy($_, "$prefixdir/include/") foreach (glob("../include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("../lib/*/*"));
    chdir $self->base_dir();
  }

  if (-d "$srcdir/cd/src") {
    print "Gonna build 'cd'\n";
    chdir "$srcdir/cd/src";
    ($cd_si =`$makesysinfo 2>&1`) =~ s/[\n\r]*$//;
    print "$cd_si\n";
    foreach my $t (@{$cdtgs}) {
      $done{$t} = $self->do_system_output_tail(1000, $make, $t, @makeopts);
      warn "###WARN### [$?] during make $t" unless $done{$t};
    }
    copy($_, "$prefixdir/include/") foreach (glob("../include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("../lib/*/*"));
    chdir $self->base_dir();
  }

  if (-d "$srcdir/iup") {
    print "Gonna build 'iup'\n";
    chdir "$srcdir/iup";
    ($iup_si =`$makesysinfo 2>&1`) =~ s/[\n\r]*$//;
    print "$iup_si\n";
    foreach my $t (@{$iuptgs}) {
      $done{$t} = $self->do_system_output_tail(1000, $make, $t, @makeopts);
      warn "###WARN### [$?] during make $t" unless $done{$t};
    }
    copy($_, "$prefixdir/include/") foreach (glob("./include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("./lib/*/*"));
    chdir $self->base_dir();
  }

  unless ($done{iup} && $done{iupim} && $done{iupcd}) {
    print "Done: $done{$_} - $_\n" foreach (sort keys %done);
    die "###MAKE FAILED### essential libs not built, giving up!";
  }

  $self->config_data('debug_done', \%done);
  $self->config_data('debug_si', { im => $im_si, cd => $cd_si, iup => $iup_si } );
  print "Build finished!\n";
  return 1;
}

sub get_make {
  my ($self) = @_;
  my $devnull = File::Spec->devnull();
  my @try = ($Config{gmake}, 'gmake', 'make', $Config{make});
  my %tested;
  print "Gonna detect GNU make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print "- testing: '$name'\n";
    my $ver = `$name --version 2> $devnull`;
    if ($ver =~ /GNU Make/i) {
      print "- found: '$name'\n";
      return $name
    }
  }
  print "- fallback to: 'make'\n";
  return 'make';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|'|'\\''|g;
    return "'$txt'";
}

1;
