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

  my %has;
  $has{gtk}     = `pkg-config --modversion gtk+-2.0 2>/dev/null` ? 1 : 0;	#iupgtk
  $has{gdk}     = `pkg-config --modversion gdk-2.0 2>/dev/null` ? 1 : 0;	#cdgdk
  $has{cairo}   = `pkg-config --modversion cairo 2>/dev/null` ? 1 : 0; 		#cdcairo
  $has{pango}   = `pkg-config --modversion pango 2>/dev/null` ? 1 : 0;		#cdcairo

  $has{l_cairo} = $self->check_lib( [] , `pkg-config --cflags cairo 2>/dev/null`, `pkg-config --libs cairo 2>/dev/null`);
  $has{l_pango} = $self->check_lib( [] , `pkg-config --cflags pango 2>/dev/null`, `pkg-config --libs pango 2>/dev/null`);
  $has{l_gtk}   = $self->check_lib( [] , `pkg-config --cflags gtk+-2.0 2>/dev/null`, `pkg-config --libs gtk+-2.0 2>/dev/null`);
  $has{l_gdk}   = $self->check_lib( [] , `pkg-config --cflags gdk-2.0 2>/dev/null`, `pkg-config --libs gdk-2.0 2>/dev/null`);
  $has{l_Xp}    = $self->check_lib( 'Xp' );
  $has{l_Xt}    = $self->check_lib( 'Xt' );
  $has{l_Xm}    = $self->check_lib( 'Xm' );
  $has{l_Xmu}   = $self->check_lib( 'Xmu' );
  $has{l_Xext}  = $self->check_lib( 'Xext' );
  $has{l_X11}   = $self->check_lib( 'X11' );
  $has{l_GL}    = $self->check_lib( 'GL' );
  $has{l_GLU}   = $self->check_lib( 'GLU' );
  $has{l_glut}  = $self->check_lib( 'glut' );
  $has{l_gdi32} = $self->check_lib( 'gdi32' );  # cygwin only
  $has{l_glu32} = $self->check_lib( 'glu32' );  # cygwin only

  $has{mot}     = $self->check_header('Xm/Xm.h');
  $has{x11}     = $self->check_header('X11/Xlib.h');		#iupgl cdx11
  $has{glx}     = $self->check_header('GL/glx.h');     		#iupgl
  $has{win}     = $self->check_header('windows.h');		#iupwin
  $has{wmsdk}   = $self->check_header('wmsdk.h');	        #im_wmv
  $has{fftw3}   = $self->check_header('fftw3.h');	        #im_fftw3 = http://www.fftw.org/
  $has{ecw}     = $self->check_header('NCSECWClient.h');	#im_format_ecw = ECW (Enhanced Compression Wavelet) format
  $has{XxXxX}   = $self->check_header('XxXxX/XxXxX.h');   	#non existing header

  #possible targets: im im_process im_jp2 im_fftw im_capture im_avi im_wmv im_fftw3 im_ecw
  my @imtargets = qw[im im_process im_jp2 im_fftw];

  #possible targets: cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl cdcontextplus cdcairo
  my @cdtargets = qw[cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl];

  #possible targets: iup iupcd iupcontrols iupim iupimglib iup_pplot iupgl
  my @iuptargets = qw[iup iupcd iupcontrols iupim iupimglib iup_pplot iupgl];

  #store debug info into ConfigData
  $self->config_data('debug_has', \%has);
  $self->config_data('debug_imtargets', \@imtargets);
  $self->config_data('debug_cdtargets', \@cdtargets);
  $self->config_data('debug_iuptargets', \@iuptargets);

  #my @makeopts  = qw[NO_DYNAMIC=Yes USE_NODEPEND=Yes];
  my @makeopts  = qw[NO_STATIC=Yes USE_NODEPEND=Yes];

  #choose GUI subsystem
  if ($has{win}) {
    push(@makeopts, 'USE_WIN=Yes');
  }
  elsif ($has{gtk}) {
    push(@makeopts, 'USE_GTK=Yes');
  }
  elsif ($has{x11}) {
    push(@makeopts, 'USE_X11=Yes');
  }
  else {
    warn "###WARN### No supported GUI subsystem (Win32, GTK, X11/Motif) detected!";
  }

  #do the job
  $self->build_via_tecmake($build_out, $srcdir, \@makeopts, \@iuptargets, \@cdtargets, \@imtargets);

  #make a list of libs necessary to link with IUP and related libraries
  my @libs;
  my ($extra_cflags, $extra_lflags) = ('', '');
  foreach (glob("$build_out/lib/*")) {
    push(@libs, $1) if ($_ =~ /lib([a-zA-Z0-9\_\-]*)\.a$/);
  }
  #priorities if multiple GUI subsystems detected: 1. Win32(cygwin), 2. GTK, 3. X11/Motif
  if ($has{win}) {
    push(@libs, qw[gdi32 comdlg32 comctl32 winspool uuid ole32 oleaut32 opengl32 glu32 glut]);
  }
  elsif ($has{gtk}) {
    #xxx kmx todo - what about cairo, pango?
    $extra_cflags = `pkg-config --cflags gtk+-2.0 gdk-2.0 2>/dev/null`;
    $extra_lflags = `pkg-config --libs gtk+-2.0 gdk-2.0 2>/dev/null`;
  }
  elsif ($has{x11}) {
    #xxx kmx todo - needs testing
    #Xmu Xt X11         # IRIX
    #Xt Xext X11        # HP-UX
    #Xmu Xp Xt Xext X11 # MacOS
    push(@libs, qw[Xmu Xt Xext X11 GL GLU]);
  }
  $self->config_data('linker_libs', \@libs);
  $self->config_data('extra_cflags', $extra_cflags);
  $self->config_data('extra_lflags', $extra_lflags);
};

sub build_via_tecmake {
  my ($self, $build_out, $srcdir, $mopts, $iuptgs, $cdtgs, $imtgs) = @_;
  $srcdir ||= 'src';
  my $prefixdir   = rel2abs($build_out);
  my $make        = $self->get_make;
  my @makesysinfo = qw/-f tecmake.mak sysinfo MAKENAME= USE_NODEPEND=Yes/;
  my @makeopts    = @{$mopts};

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
    $self->do_system($make, @makesysinfo); ## maybe store into configdata xxx
    foreach my $t (@{$imtgs}) {
      my @cmd = ($make, $t, @makeopts);
      print "Running make $t ...\n(cmd: ".join(' ',@cmd).")\n";
      $done{$t} = $self->do_system(@cmd) ? 1 : 0;
      warn "###WARN### [$?] during make $t" unless $done{$t};
    }
    copy($_, "$prefixdir/include/") foreach (glob("../include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("../lib/*/*"));
    chdir $self->base_dir();
  }

  if (-d "$srcdir/cd/src") {
    print "Gonna build 'cd'\n";
    chdir "$srcdir/cd/src";
    $self->do_system($make, @makesysinfo); ## maybe store into configdata xxx
    foreach my $t (@{$cdtgs}) {
      my @cmd = ($make, $t, @makeopts);
      print "Running make $t ...\n(cmd: ".join(' ',@cmd).")\n";
      $done{$t} = $self->do_system(@cmd) ? 1 : 0;
      warn "###WARN### [$?] during make $t" unless $done{$t};
    }
    copy($_, "$prefixdir/include/") foreach (glob("../include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("../lib/*/*"));
    chdir $self->base_dir();
  }

  if (-d "$srcdir/iup") {
    print "Gonna build 'iup'\n";
    chdir "$srcdir/iup";
    $self->do_system($make, @makesysinfo); ## maybe store into configdata xxx
    foreach my $t (@{$iuptgs}) {
      my @cmd = ($make, $t, @makeopts);
      print "Running make $t ...\n(cmd: ".join(' ',@cmd).")\n";
      $done{$t} = $self->do_system(@cmd) ? 1 : 0;
      warn "###WARN### [$?] during make $t" unless $done{$t};
    }
    copy($_, "$prefixdir/include/") foreach (glob("./include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("./lib/*/*"));
    chdir $self->base_dir();
  }

  $self->config_data('debug_done', \%done);
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
