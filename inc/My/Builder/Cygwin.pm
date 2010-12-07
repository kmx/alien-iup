package My::Builder::Cygwin;

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
  my $success = 1;

  #possible targets:  im im_process im_jp2 im_fftw im_capture im_avi im_wmv
  #possible targets:  cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl cdcontextplus cdcairo
  #possible targets:  iup iupcd iupcontrols iup_pplot iupgl iupim iupimglib iupole iupweb iuptuio
  my @imtargets  = qw[im im_process im_jp2 im_fftw];
  my @cdtargets  = qw[cd_freetype cd_ftgl cd cd_pdflib cdpdf cdgl];
  my @iuptargets = qw[iup iupcd iupcontrols iup_pplot iupgl iupim iupimglib iupole iuptuio]; #NOTE: we do not even try to build iupweb!

  if (!$self->notes('is_devel_cvs_version')) { # xxx hack (skip some targets if not devel distribution)
    if ($^O eq 'cygwin' && $Config{gccversion} =~ /^3\.4\.4/) {
      warn "###WARN### skipping iuptuio on Cygwin+gcc3";
      @iuptargets = grep { $_ !~ /^iuptuio$/ } @iuptargets;
    }
  }

  #make options
  my @makeopts   = qw[USE_NODEPEND=Yes];

  #store debug info into ConfigData
  $self->config_data('info_imtargets', \@imtargets);
  $self->config_data('info_cdtargets', \@cdtargets);
  $self->config_data('info_iuptargets', \@iuptargets);
  $self->config_data('info_gui_driver', 'Win32/native');

  #do the job
  $success = $self->build_via_tecmake($build_out, $srcdir, \@makeopts, \@iuptargets, \@cdtargets, \@imtargets);
  warn "###MAKE FAILED###" unless $success;

  #make a list of libs necessary to link with IUP and related libraries
  my %seen;
  my @gl_l = glob("$build_out/lib/*");
  my @gl_i = glob("$build_out/include/*");
  print STDERR "Output counts: lib=" . scalar(@gl_l) . " include=" . scalar(@gl_i) . "\n";
  if ((scalar(@gl_l) < 3) || (scalar(@gl_i) < 3)) {
    warn "###WARN### $build_out/lib/ or $build_out/include/ not complete";
    $success = 0;
  }
  foreach (@gl_l) {
    if ($_ =~ /lib([a-zA-Z0-9\_\-\.]*?)\.(a|dll\.a)$/) {
      $seen{$1} = 1;
    }
    elsif ($_ !~ /\.dll$/) { # *.dll on cygwin is OK
      warn "###WARN### Unexpected filename '$_'";
      $success = 0;
    }
  }
  print STDERR "Output libs: $_\n" foreach (sort keys %seen);
  my @libs = $self->sort_libs(keys %seen);

  $self->config_data('extra_cflags', '');
  $self->config_data('extra_lflags', '');
  $self->config_data('linker_libs', [ @libs, qw/gdi32 comdlg32 comctl32 winspool uuid ole32 oleaut32 opengl32 glu32/ ] );

  die "###BUILD ABORTED###" unless $success;
  print STDERR "Build finished sucessfully!\n";
};

sub build_via_tecmake {
  my ($self, $build_out, $srcdir, $mopts, $iuptgs, $cdtgs, $imtgs) = @_;
  my $prefixdir = rel2abs($build_out);

  my $success = 1;

  #create output directory structure
  mkdir "$prefixdir" unless -d "$prefixdir";
  mkdir "$prefixdir/lib" unless -d "$prefixdir/lib";
  mkdir "$prefixdir/include" unless -d "$prefixdir/include";

  my %done;
  my $tecuname = 'gcc4';
  #my $tecuname = 'dllg4';
  my @basecmd = ("make", "TEC_UNAME=$tecuname");

  if(-d "$srcdir/im/src") {
    print STDERR "Gonna build 'im'\n";
    chdir "$srcdir/im/src";
    foreach my $t (@$imtgs) {
      $done{"im:$t"} = $self->run_custom(@basecmd, @$mopts, $t);
      $success = 0 unless $done{"im:$t"};
    }
    copy($_, "$prefixdir/include/") foreach (glob("../include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("../lib/$tecuname/*"));
    chdir $self->base_dir();
  }

  if (-d "$srcdir/cd/src") {
    print STDERR "Gonna build 'cd'\n";
    chdir "$srcdir/cd/src";
    foreach my $t (@$cdtgs) {
      $done{"cd:$t"} = $self->run_custom(@basecmd, @$mopts, $t);
      $success = 0 unless $done{"cd:$t"};
    }
    copy($_, "$prefixdir/include/") foreach (glob("../include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("../lib/$tecuname/*"));
    chdir $self->base_dir();
  }

  if (-d "$srcdir/iup") {
    print STDERR "Gonna build 'iup'\n";
    chdir "$srcdir/iup";
    foreach my $t (@$iuptgs) {
      $done{"iup:$t"} = $self->run_custom(@basecmd, @$mopts, $t);
      $success = 0 unless $done{"iup:$t"};
    }
    copy($_, "$prefixdir/include/") foreach (glob("./include/*.h"));
    copy($_, "$prefixdir/lib/") foreach (glob("./lib/$tecuname/*"));
    chdir $self->base_dir();
  }

  print STDERR "Done: $done{$_} - $_\n" foreach (sort keys %done);
  # save it for future use in ConfigData
  $self->config_data('build_prefix', $prefixdir);
  $self->config_data('info_makeopts', $mopts);
  $self->config_data('info_done', \%done);

  return $success;
}

sub get_make {
  # on cygwin always 'make'
  return 'make';
}

sub quote_literal {
    my ($self, $txt) = @_;
    $txt =~ s|'|'\\''|g;
    return "'$txt'";
}

1;
