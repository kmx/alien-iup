#!perl -T

use Test::More tests => 2;
use Data::Dumper;

use_ok( 'Alien::IUP' );
use_ok( 'Alien::IUP::ConfigData' );

diag "This test shows misc debug info";

diag "Source URLs:";
diag Alien::IUP::ConfigData->config('iup_url') || 'n.a.';
diag Alien::IUP::ConfigData->config('im_url') || 'n.a.';
diag Alien::IUP::ConfigData->config('cd_url') || 'n.a.';

diag "TARGETS (im) : ". join(' ', @{Alien::IUP::ConfigData->config('info_imtargets')})  if Alien::IUP::ConfigData->config('info_imtargets');
diag "TARGETS (cd) : ". join(' ', @{Alien::IUP::ConfigData->config('info_cdtargets')})  if Alien::IUP::ConfigData->config('info_cdtargets');
diag "TARGETS (iup): ". join(' ', @{Alien::IUP::ConfigData->config('info_iuptargets')}) if Alien::IUP::ConfigData->config('info_iuptargets');
diag "MAKEOPTS     : ". join(' ', @{Alien::IUP::ConfigData->config('info_makeopts')})   if Alien::IUP::ConfigData->config('info_makeopts');
diag "GUI DRIVER   : ". Alien::IUP::ConfigData->config('info_gui_driver')               if Alien::IUP::ConfigData->config('info_gui_driver');

my $h = Alien::IUP::ConfigData->config('info_has');
my $l = Alien::IUP::ConfigData->config('info_lib_details');
diag "Detected libraries/headers:";
if ($h) {
  foreach (sort keys %$h) {
    my $detail = '';
    $detail = sprintf("version=%s prefix=%s", $l->{$_}->{version}, $l->{$_}->{prefix}) if defined $l->{$_};
    diag " $h->{$_} - $_ $detail";
  }
}
else {
  diag " N/A";
}

my $d = Alien::IUP::ConfigData->config('info_done');
diag "Build/make results per target:";
if ($d) {
  diag " $d->{$_} - $_" foreach (sort keys %$d);
}
else {
  diag " N/A";
}
