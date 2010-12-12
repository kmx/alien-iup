use 5.008;
use strict;
use warnings;
use Module::Build;

use lib 'inc';

my %platforms =(
  # Unix = default, thus not listing all UNIX like systems
  MSWin32 => 'Windows',
  cygwin  => 'Cygwin',
  linux   => 'Unix',
);
my $package = 'My::Builder::' . ($platforms{$^O} || 'Unix');
print STDERR "Gonna use '$package' class ...\n";
eval "require $package" or die "###ERROR### Require '$package' failed: $@\n";

my $builder = $package->new(
  module_name        => 'Alien::IUP',
  dist_version_from  => 'lib/Alien/IUP.pm',
  dist_author        => 'KMX, kmx@cpan.org',
  license            => 'mit',
  requires => {
    'perl'              => 5.008,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
  },
  configure_requires => {
    'perl'              => 5.008,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Find'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0.041, # we need return_if_system_error
  },
  build_requires => {
    'perl'              => 5.008,
    'Test::More'        => 0,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Find'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'File::Fetch'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0.041, # we need return_if_system_error
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'Alien-IUP-*' ],
  #create_makefile_pl => 'small', # creating Makefile.PL to satisfy old CPAN clients (does not work well with our style of M::B use)
  create_readme      => 1,
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-IUP',
      repository => 'http://github.com/kmx/alien-iup',
    }
  },
);

unlink 'build_done'; # delete build marker (= force rebuild after running Build.PL)
$builder->add_to_cleanup("sharedir/" . $builder->{properties}->{dist_version}); # catfile() would be better
$builder->add_to_cleanup('build_done');
$builder->add_to_cleanup('build_src');

if ($builder->check_installed_lib()) {
  my $ans = $builder->prompt("\nIUP detected, wanna use IUP already installed on your system (y/n)?", 'y');
  $builder->notes('already_installed_lib', undef) unless (lc($ans) eq 'y');
}

# set to 0 (zero) if you do not want a devel distribution version
$builder->notes('is_devel_cvs_version', 0);

# set what tarballs we are gonna use
if ($builder->notes('is_devel_cvs_version')) {
  $builder->notes('build_debug_info', 1);
  warn "###\n";
  warn "###BEWARE: this is a devel version based on CVS sources (might be unstable)!\n";
  warn "###sources exported from CVS at 2010/12/12-08:55:06\n";
  warn "###\n";
  $builder->notes('iup_url',  'http://strawberryperl.com/package/kmx/testing/iup-cvs-101212.tar.gz');
  $builder->notes('iup_sha1', '763b8edf309adaffe05423f44c70a9ed66d93c81');
  $builder->notes('im_url',   'http://strawberryperl.com/package/kmx/testing/im-cvs-101212.tar.gz');
  $builder->notes('im_sha1',  '92127110e4e175afe81166299192cff20d14ad85');
  $builder->notes('cd_url',   'http://strawberryperl.com/package/kmx/testing/cd-cvs-101212.tar.gz');
  $builder->notes('cd_sha1',  'b5b10fce082ebf871391c77764a1826e0dc041cc');

  if ($builder->dist_version !~ /_/) {
    warn "###ERROR### version number:".$builder->dist_version." does not seem to be devel-like! Gonna exit\n";
    exit 0;
  }
}
else {
  $builder->notes('build_debug_info', lc($builder->prompt("\nWanna see more debug info during build (y/n)?", 'y')) eq 'y' ? 1 : 0);

  $builder->notes('iup_url', 'http://download.sf.net/iup/iup-3.3_Sources.tar.gz');
  $builder->notes('iup_sha1', '6ce0badbad9e27131010bf6fd296b1d5c8eda0a8');
  $builder->notes('iup_patches', [ 'patches/iup-long-long.diff',
                                   'patches/iup-tuio-ms64bit.diff',
                                   'patches/iup-tuio-ntohl.diff',
                                   'patches/iup-GTK_WIDGET.diff',
                                   'patches/iup-gtk-tabs.diff',
                                   'patches/iup-WIN32_WINNT.diff' ] );
  $builder->notes('im_url', 'http://download.sf.net/imtoolkit/im-3.6.3_Sources.tar.gz');
  $builder->notes('im_sha1', '93f5e1fef25d9ac42a8c3a628411156b695cd7d1');
  $builder->notes('im_patches', [ 'patches/im-int64.diff',
                                  'patches/im-INC-order.diff',
                                  'patches/im-dragonfly.diff' ] );
  $builder->notes('cd_url', 'http://download.sf.net/canvasdraw/cd-5.4.1_Sources.tar.gz');
  $builder->notes('cd_sha1', 'b771752f253ab3bf6ee8c4bea228d5d16f4352ec');
  $builder->notes('cd_patches', [ 'patches/cd-dragonfly.diff',
                                  'patches/cd-GTK_BASE.diff'  ] );
}

# check if we have GNU make otherwise 'exit 0' - cpan testers will report "N/A"
my $m = $builder->get_make;
exit 0 unless $m;
$builder->notes('gnu_make', $m);

$builder->create_build_script();
