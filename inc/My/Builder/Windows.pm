package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Glob qw(bsd_glob glob);
use Config;

sub build_binaries {
  my ($self, $build_out, $srcdir) = @_;
  my $prefixdir = rel2abs($build_out);
  my $perl = $^X;
  my @imtargets;
  my @cdtargets;
  my @iuptargets;

  #possible targets:  im im_process im_jp2 im_fftw im_capture im_avi im_wmv
  #possible targets:  cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl cdcontextplus cdcairo
  #possible targets:  iup iupcd iupcontrols iup_pplot iupgl iupim iupimglib iupole iupweb iuptuio
  
  if ($self->notes('is_devel_cvs_version')) {
    ### DEVEL BUILD ###
    @imtargets  = qw[im im_process im_jp2 im_fftw]; #xxx im_capture removed
    @cdtargets  = qw[cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl]; #xxx add cdcontextplus
    @iuptargets = qw[iup iupcd iupcontrols iup_pplot iupgl iupim iupimglib iupole iupweb iuptuio];
  }
  else {
    @imtargets  = qw[im];
    @cdtargets  = qw[cd_freetype cd];
    @iuptargets = qw[iup iupcd iupcontrols iup_pplot iupgl iupim iupimglib iupole];
    if ($Config{cc} =~ /cl/ && $Config{ccversion} =~ /^12\./) {
      warn "###WARN### skipping cd_ftgl+iuptuio on VC6";
      @cdtargets  = grep { $_ !~ /^(cd_ftgl)$/ } @cdtargets;     # disable just when compiling via VC6
      @iuptargets = grep { $_ !~ /^(iuptuio)$/ } @iuptargets;    # disable just when compiling via VC6
    }
  }
  
  #xxx TODO add cdcontextplus + iupweb support to makefiles
  @cdtargets  = grep { $_ !~ /^(cdcontextplus)$/ } @cdtargets; # xxx TODO: makefiles not ready yet; does not compile on mingw/gcc
  @iuptargets = grep { $_ !~ /^(iupweb)$/ } @iuptargets;       # xxx TODO: makefiles not ready yet; does not compile on mingw/gcc

  #store debug info into ConfigData
  $self->config_data('info_imtargets', \@imtargets);
  $self->config_data('info_cdtargets', \@cdtargets);
  $self->config_data('info_iuptargets', \@iuptargets);
  $self->config_data('info_gui_driver', 'Win32/native');

  my (@cmd_im, @cmd_cd, @cmd_iup);
  if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/) { # MSVC compiler
    @cmd_im  = ( $Config{make}, '-f', rel2abs('patches\Makefile_im.nmake'),  "PERL=perl", "PREFIX=$prefixdir" );
    @cmd_cd  = ( $Config{make}, '-f', rel2abs('patches\Makefile_cd.nmake'),  "PERL=perl", "PREFIX=$prefixdir" );
    @cmd_iup = ( $Config{make}, '-f', rel2abs('patches\Makefile_iup.nmake'), "PERL=perl", "PREFIX=$prefixdir" );
    if ($Config{archname} =~ /x64/) { #64bit
      push(@cmd_im,  'CFG=Win64');
      push(@cmd_cd,  'CFG=Win64');
      push(@cmd_iup, 'CFG=Win64');
    }
  }
  else { # gcc compiler
    my $make = $self->notes('gnu_make') || $self->get_make;
    die "###ERROR## make command not defined" unless $make;
    # for GNU make on MS Windows it is safer to convert \ to /
    $perl =~ s|\\|/|g;
    $prefixdir =~ s|\\|/|g;
    @cmd_im  = ( $make, '-f', rel2abs('patches\Makefile_im.mingw'),  "PERL=$perl", "PREFIX=$prefixdir" );
    @cmd_cd  = ( $make, '-f', rel2abs('patches\Makefile_cd.mingw'),  "PERL=$perl", "PREFIX=$prefixdir" );
    @cmd_iup = ( $make, '-f', rel2abs('patches\Makefile_iup.mingw'), "PERL=$perl", "PREFIX=$prefixdir" );
    if ($Config{archname} =~ /x64/) { #64bit
      push(@cmd_im,  'BUILDBITS=64');
      push(@cmd_cd,  'BUILDBITS=64');
      push(@cmd_iup, 'BUILDBITS=64');
    }
  }

  my $libtype = 'static';
  my $success = 1;
  my %done;

  if(-d "$srcdir/im/src") {
    print STDERR "Gonna build 'im'\n";
    chdir "$srcdir/im/src";
    foreach my $t (@imtargets) {
      print STDERR ">>>>> Building 'im:$t'\n";
      $done{"im:$t"} = $self->run_custom(@cmd_im, $t.'-'.$libtype);
      warn "###WARNING### error during make(im:$t)" unless $done{"im:$t"};
      $success = 0 unless $done{"im:$t"};
    }
    $self->run_custom(@cmd_im, 'install-all');
    chdir $self->base_dir();
  }

  if (-d "$srcdir/cd/src") {
    print STDERR "Gonna build 'cd'\n";
    chdir "$srcdir/cd/src";
    foreach my $t (@cdtargets) {
      print STDERR ">>>>> Building 'cd:$t'\n";
      $done{"cd:$t"} = $self->run_custom(@cmd_cd, $t.'-'.$libtype);
      warn "###WARNING### error during make(cd:$t)" unless $done{"cd:$t"};
      $success = 0 unless $done{"cd:$t"};
    }
    $self->run_custom(@cmd_cd, 'install-all');
    chdir $self->base_dir();
  }

  if (-d "$srcdir/iup") {
    print STDERR "Gonna build 'iup'\n";
    chdir "$srcdir/iup";
    foreach my $t (@iuptargets) {
      print STDERR ">>>>> Building 'iup:$t'\n";
      $done{"iup:$t"} = $self->run_custom(@cmd_iup, $t.'-'.$libtype);
      warn "###WARNING### error during make(iup:$t)" unless $done{"iup:$t"};
      $success = 0 unless $done{"iup:$t"};
    }
    $self->run_custom(@cmd_iup, 'install-all');
    chdir $self->base_dir();
  }

  # go through really existing libs
  my %seen;
  my @gl_l = glob("$prefixdir/lib/*");
  foreach (@gl_l) {
    print STDERR "Created lib: $_\n" if $self->notes('build_debug_info');
    if ($_ =~ /lib([a-zA-Z0-9\_\-\.]*?)\.(a|dll\.a)$/) { #gcc
      $seen{$1} = 1;
    }
    elsif ($_ =~ /([a-zA-Z0-9\_\-\.]*?)\.(lib)$/) { #msvc
      $seen{$1} = 1;
    }
    else {
      warn "###WARN### Unexpected filename '$_'";
    }
  }

  # xxx TODO: maybe more libs needed like - gdiplus ...
  my @iuplibs = $self->sort_libs(keys %seen);
  $self->config_data('iup_libs', {map {$_=>1} @iuplibs} );
  $self->config_data('linker_libs', [ @iuplibs, qw/gdi32 comdlg32 comctl32 winspool uuid ole32 oleaut32 opengl32 glu32/ ] );
  $self->config_data('extra_cflags', '');
  $self->config_data('extra_lflags', '');
  $self->config_data('info_done', \%done);
  
  print STDERR "Build finished!\n";
  return $success;
}

sub get_make {
  my ($self) = @_;
  my @try = ( 'dmake', 'mingw32-make', 'gmake', 'make', $Config{make}, $Config{gmake} );
  print STDERR "Gonna detect make\n" if $self->notes('build_debug_info');
  foreach my $name ( @try ) {
    next unless $name;
    print STDERR "- testing: '$name'\n" if $self->notes('build_debug_info');
    if (system("$name --help 2>nul 1>nul") != 256) {
      # I am not sure if this is the right way to detect non existing executable
      # but it seems to work on MS Windows (more or less)
      print STDERR "- found: '$name'\n" if $self->notes('build_debug_info');
      return $name;
    };
  }
  print STDERR "- fallback to: 'dmake'\n" if $self->notes('build_debug_info');
  return 'dmake';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|"|\\"|g;
    return qq("$txt");
}

1;
