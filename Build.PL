use 5.008;
use strict;
use warnings;
use Module::Build;

use lib 'inc';

my %platforms =(  
  MSWin32   => 'Windows',
  cygwin    => 'Cygwin',
  linux     => 'Unix',
  _default_ => 'Unix', # Unix = default, thus not listing all UNIX like systems
);

my $package = 'My::Builder::' . ($platforms{$^O} || $platforms{_default_});
eval "require $package" or die "###ERROR### Require '$package' failed: $@";
print STDERR "Gonna use '$package' class ...\n";

my $cvs_src;

my $builder = $package->new(
  module_name        => 'Alien::IUP',
  dist_version_from  => 'lib/Alien/IUP.pm',
  dist_author        => 'KMX, kmx@cpan.org',
  license            => 'mit',
  requires => {
    'perl'              => 5.008008,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
  },
  configure_requires => {
    'perl'              => 5.008008,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Find'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0,
    'ExtUtils::Liblist' => 0,
    'LWP::Simple'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0.041, # we need return_if_system_error
  },
  build_requires => {
    'perl'              => 5.008008,
    'Test::More'        => 0,
    'File::ShareDir'    => 0,
    'File::Spec'        => 0,
    'File::Path'        => 0,
    'File::Temp'        => 0,
    'File::Find'        => 0,
    'ExtUtils::CBuilder'=> 0,
    'ExtUtils::Command' => 0, #Win32 external makefiles need this
    'ExtUtils::Liblist' => 0,
    'LWP::Simple'       => 0,
    'Digest::SHA'       => 0,
    'Archive::Extract'  => 0,
    'Text::Patch'       => 0,
    'IPC::Run3'         => 0.041, # we need return_if_system_error
  },
  share_dir          => 'sharedir',
  add_to_cleanup     => [ 'Alien-IUP-*' ],
  get_options => { 'cvs' => { qw(type :s  store) => \$cvs_src } },
  #create_makefile_pl => 'small', # creating Makefile.PL to satisfy old CPAN clients (does not work well with our style of M::B use)
  create_readme      => 1,
  meta_merge => {
    resources  => {
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-IUP',
      repository => 'https://github.com/kmx/alien-iup',
    }
  },
);

unlink 'build_done'; # delete build marker (= force rebuild after running Build.PL)
$builder->add_to_cleanup("sharedir/" . $builder->{properties}->{dist_version}); # catfile() would be better
$builder->add_to_cleanup('build_done');
$builder->add_to_cleanup('build_src');

if (defined $cvs_src) { ### use the latest sources from iup repository
  warn "###\n";
  warn "###BEWARE: gonna use CVS sources (might be unstable)!\n";
  warn "###\n";
  $builder->notes('iup_url',  'https://github.com/kmx/mirror-iup/tarball/master');
  $builder->notes('iup_sha1', 'DO_NOT_CHECK_SHA1');
  $builder->notes('im_url',   'https://github.com/kmx/mirror-im/tarball/master');
  $builder->notes('im_sha1',  'DO_NOT_CHECK_SHA1');
  $builder->notes('cd_url',   'https://github.com/kmx/mirror-cd/tarball/master');
  $builder->notes('cd_sha1',  'DO_NOT_CHECK_SHA1');
  $builder->notes('build_debug_info', 1);
  $builder->notes('is_devel_cvs_version', 1)
}
else {
  if ($builder->check_installed_lib()) {
    my $ans = $builder->prompt("\nIUP detected, wanna use IUP already installed on your system (y/n)?", 'y');
    $builder->notes('already_installed_lib', undef) unless (lc($ans) eq 'y');
  }
  $builder->notes('build_debug_info', lc($builder->prompt("\nWanna see more debug info during build (y/n)?", 'n')) eq 'y' ? 1 : 0);

  # set what tarballs we are gonna use
  $builder->notes('iup_url', 'http://download.sf.net/iup/iup-3.5_Sources.tar.gz');
  $builder->notes('iup_sha1', 'e5a3fdde13dcf77eeb5e690b21ff198389b1e889');
  $builder->notes('iup_patches', [ qw!patches/iup-kfreebsd.diff! ] );

  $builder->notes('im_url', 'http://download.sf.net/imtoolkit/im-3.6.3_Sources.tar.gz');
  $builder->notes('im_sha1', '14a800e3e1642acb97c569bd7f50d413fa375d5a');
  $builder->notes('im_patches', [ qw!patches/im-dragonfly.diff patches/im-kfreebsd.diff! ] );

  $builder->notes('cd_url', 'http://download.sf.net/canvasdraw/cd-5.4.1_Sources.tar.gz');
  $builder->notes('cd_sha1', '07e6c6edbbfa76667a8cb8e59beb51a54dc59147');
  $builder->notes('cd_patches', [ qw!patches/cd-dragonfly.diff patches/cd-kfreebsd.diff! ] );
}

# check if we have GNU make otherwise 'exit 0' - cpan testers will report "N/A"
my $m = $builder->get_make;
exit 0 unless $m;
$builder->notes('gnu_make', $m);

$builder->create_build_script();
