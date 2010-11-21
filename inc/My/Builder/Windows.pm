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

  #targets: install-static install-dynamic install
  my $target = 'install-static';

  my (@cmd_im, @cmd_cd, @cmd_iup);
  if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/) { # MSVC compiler
    @cmd_im  = ( $Config{make}, '-f', rel2abs('patches\Makefile_im.nmake'),  "PERL=perl", "PREFIX=$prefixdir", $target );
    @cmd_cd  = ( $Config{make}, '-f', rel2abs('patches\Makefile_cd.nmake'),  "PERL=perl", "PREFIX=$prefixdir", $target );
    @cmd_iup = ( $Config{make}, '-f', rel2abs('patches\Makefile_iup.nmake'), "PERL=perl", "PREFIX=$prefixdir", $target );
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
    @cmd_im  = ( $make, '-f', rel2abs('patches\Makefile_im.mingw'),  "PERL=$perl", "PREFIX=$prefixdir", $target );
    @cmd_cd  = ( $make, '-f', rel2abs('patches\Makefile_cd.mingw'),  "PERL=$perl", "PREFIX=$prefixdir", $target );
    @cmd_iup = ( $make, '-f', rel2abs('patches\Makefile_iup.mingw'), "PERL=$perl", "PREFIX=$prefixdir", $target );
    if ($Config{archname} =~ /x64/) { #64bit
      push(@cmd_im,  'BUILDBITS=64');
      push(@cmd_cd,  'BUILDBITS=64');
      push(@cmd_iup, 'BUILDBITS=64');
    }
  }

  my @iup_libs = qw/iup cd im cdgl cdpdf freetype6 ftgl im_fftw im_jp2 im_process iup_pplot iupcd iupcontrols iupgl iupim iupimglib pdflib/;
  my $success;
  # xxx TODO maybe detect real existing libs after make

  if(-d "$srcdir/im/src") {
    print STDERR "Gonna build 'im'\n";
    chdir "$srcdir/im/src";
    $success = $self->run_custom(@cmd_im);
    die "###ERROR### error [$?] during make(im)" unless $success;
    chdir $self->base_dir();
  }

  if (-d "$srcdir/cd/src") {
    print STDERR "Gonna build 'cd'\n";
    chdir "$srcdir/cd/src";    
    $success = $self->run_custom(@cmd_cd);
    die "###ERROR### error [$?] during make(cd)" unless $success;
    chdir $self->base_dir();
  }

  if (-d "$srcdir/iup") {
    print STDERR "Gonna build 'iup'\n";
    chdir "$srcdir/iup";
    $success = $self->run_custom(@cmd_iup);
    die "###ERROR### error [$?] during make(iup)" unless $success;
    chdir $self->base_dir();
  }

  if ($self->notes('build_debug_info')) {
    my @l = bsd_glob("$prefixdir/lib/*");
    print STDERR "Created lib: $_\n" foreach (@l);
  }

  $self->config_data('extra_cflags', '');
  $self->config_data('extra_lflags', '');
  $self->config_data('linker_libs', [ $self->sort_libs(@iup_libs), qw/gdi32 comdlg32 comctl32 winspool uuid ole32 oleaut32 opengl32 glu32/ ] );

  print STDERR "Build finished sucessfully!\n";
  return 1;
}

sub get_make {
  my ($self) = @_;
  my @try = ( 'dmake', 'mingw32-make', 'gmake', 'make', $Config{make}, $Config{gmake} );
  print STDERR "Gonna detect make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    print STDERR "- testing: '$name'\n";
    if (system("$name --help 2>nul 1>nul") != 256) {
      # I am not sure if this is the right way to detect non existing executable
      # but it seems to work on MS Windows (more or less)
      print STDERR "- found: '$name'\n";
      return $name;
    };
  }
  print STDERR "- fallback to: 'dmake'\n";
  return 'dmake';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|"|\\"|g;
    return qq("$txt");
}

1;
