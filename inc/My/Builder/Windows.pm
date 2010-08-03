package My::Builder::Windows;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use Config;

sub build_binaries {
  my ($self, $build_out, $srcdir) = @_;
  my $prefixdir = rel2abs($build_out);
  my $perl = $^X;

  print "Checking available libraries/headers...\n";
  my %has;

  $has{gtk}     = `pkg-config --modversion gtk+-2.0 2>nul` ? 1 : 0;        #iupgtk
  $has{gdk}     = `pkg-config --modversion gdk-2.0 2>nul` ? 1 : 0;        #cdgdk
  $has{cairo}   = `pkg-config --modversion cairo 2>nul` ? 1 : 0;                 #cdcairo
  $has{pango}   = `pkg-config --modversion pango 2>nul` ? 1 : 0;                #cdcairo

  $has{l_cairo} = $self->check_lib( [] , `pkg-config --cflags cairo 2>nul`, `pkg-config --libs cairo 2>nul`);
  $has{l_pango} = $self->check_lib( [] , `pkg-config --cflags pango 2>nul`, `pkg-config --libs pango 2>nul`);
  $has{l_pangox}= $self->check_lib( [] , `pkg-config --cflags pangox 2>nul`, `pkg-config --libs pangox 2>nul`);
  $has{l_gtk}   = $self->check_lib( [] , `pkg-config --cflags gtk+-2.0 2>nul`, `pkg-config --libs gtk+-2.0 2>nul`);
  $has{l_gtkx11}= $self->check_lib( [] , `pkg-config --cflags gtk+-x11-2.0 2>nul`, `pkg-config --libs gtk+-x11-2.0 2>nul`);
  $has{l_gdk}   = $self->check_lib( [] , `pkg-config --cflags gdk-2.0 2>nul`, `pkg-config --libs gdk-2.0 2>nul`);
  $has{l_gdkx11}= $self->check_lib( [] , `pkg-config --cflags gdk-x11-2.0 2>nul`, `pkg-config --libs gdk-x11-2.0 2>nul`);
  $has{l_GL}    = $self->check_lib( 'GL' );
  $has{l_GLU}   = $self->check_lib( 'GLU' );
  $has{l_glut}  = $self->check_lib( 'glut' );
  $has{l_gdi32} = $self->check_lib( 'gdi32' );  # cygwin only
  $has{l_glu32} = $self->check_lib( 'glu32' );  # cygwin only

  $has{glx}     = $self->check_header('GL/glx.h');                     #iupgl
  $has{win}     = $self->check_header('windows.h');                #iupwin
  $has{wmsdk}   = $self->check_header('wmsdk.h');                #im_wmv
  $has{fftw3}   = $self->check_header('fftw3.h');                #im_fftw3 = http://www.fftw.org/
  $has{ecw}     = $self->check_header('NCSECWClient.h');        #im_format_ecw = ECW (Enhanced Compression Wavelet) format
  $has{XxXxX}   = $self->check_header('XxXxX/XxXxX.h');           #non existing header

  print "Has: $has{$_} - $_\n" foreach (sort keys %has);

  die "###ERROR### Build for MS Windows not implemented yet"; # xxx kmx todo

  # for GNU make on MS Windows it is safer to convert \ to /
  $perl =~ s|\\|/|g;
  $prefixdir =~ s|\\|/|g;

  my $make = $self->get_make;
  print "Gonna call make install ...\n";
  my @cmd;
  if($make =~ /nmake/ && $Config{make} =~ /nmake/ && $Config{cc} =~ /cl/) { # MSVC compiler
    my $makefile = rel2abs('patches\Makefile.nmake');
    if ($Config{archname} =~ /x64/) { #64bit
      @cmd = ( $make, '-f', $makefile, "PERL=perl", "PREFIX=$prefixdir", "CFG=Win64", "install" );
    }
    else { #32bit
      @cmd = ( $make, '-f', $makefile, "PERL=perl", "PREFIX=$prefixdir", "install" );
    }
  }
  else { # gcc compiler
    my $makefile = rel2abs('patches\Makefile.mingw');
    @cmd = ( $make, '-f', $makefile, "PERL=$perl", "PREFIX=$prefixdir", "CC=$Config{cc}", "install" );
  }
  print "[cmd: ".join(' ',@cmd)."]\n";
  chdir $srcdir;
  $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";
  chdir $self->base_dir();

  return 1;
}

sub get_make {
  my ($self) = @_;
  my @try = ( 'dmake', 'mingw32-make', 'gmake', 'make', $Config{make}, $Config{gmake} );
  print "Gonna detect make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    print "- testing: '$name'\n";
    if (system("$name --help 2>nul 1>nul") != 256) {
      # I am not sure if this is the right way to detect non existing executable
      # but it seems to work on MS Windows (more or less)
      print "- found: '$name'\n";
      return $name;
    };
  }
  print "- fallback to: 'dmake'\n";
  return 'dmake';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|"|\\"|g;
    return qq("$txt");
}

1;
