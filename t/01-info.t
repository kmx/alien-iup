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

diag "TARGETS (im) : ". join(' ', @{Alien::IUP::ConfigData->config('debug_imtargets')})  if Alien::IUP::ConfigData->config('debug_imtargets');
diag "TARGETS (cd) : ". join(' ', @{Alien::IUP::ConfigData->config('debug_cdtargets')})  if Alien::IUP::ConfigData->config('debug_cdtargets');
diag "TARGETS (iup): ". join(' ', @{Alien::IUP::ConfigData->config('debug_iuptargets')}) if Alien::IUP::ConfigData->config('debug_iuptargets');
diag "MAKEOPTS     : ". join(' ', @{Alien::IUP::ConfigData->config('debug_makeopts')})   if Alien::IUP::ConfigData->config('debug_makeopts');

diag "Detected libraries/headers:";
my $h = Alien::IUP::ConfigData->config('debug_has');
diag " $h->{$_} - $_" foreach (sort keys %$h);

diag "Build/make results per target:";
my $d = Alien::IUP::ConfigData->config('debug_done');
diag " $d->{$_} - $_" foreach (sort keys %$d);

diag "Tecmake sysinfo:";
diag Alien::IUP::ConfigData->config('debug_si');
