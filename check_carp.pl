#!/usr/local/bin/perl

use strict;
use warnings;

my @interfaces = split(/ /, `ifconfig -l`);
my ( %ok, %critical);

foreach my $interface (@interfaces) {
        chomp($interface);
        my @status = split(/^/m, `ifconfig $interface | grep carp | cut -d' ' -f2`);
        chomp(@status);
        my ($iface_carp_changed, $iface_carp_status);
        if (@status) {
                my $counter = 0;
                for my $status (@status) {
                        $iface_carp_changed = "/tmp/carp_changed_${interface}_${counter}";
                        $iface_carp_status = "/tmp/carp_status_${interface}_${counter}";
                        if (-f $iface_carp_changed and -f $iface_carp_status) {
                                open (FILE,"< $iface_carp_status") || die "problem opening $iface_carp_status\n";
                                my $old_status = <FILE>;
                                close FILE;
                                if ($status eq $old_status) {
                                        unlink $iface_carp_changed;
                                        open (FILE, '>', $iface_carp_status) || die "problem opening $iface_carp_status\n";
                                        print FILE ($status);
                                        close(FILE);
                                        $ok{$interface} = $status;
                                        $counter++;
                                }
                        }
                        if (-f $iface_carp_status) {
                                open (FILE, '<', $iface_carp_status) || die "problem opening $iface_carp_status\n";
                                my $old_status = <FILE>;
                                close FILE;
                                if ($status eq $old_status) {
                                        $ok{$interface} = $status;
                                        $counter++;
                                }
                                else {
                                        open (FILE, '>', $iface_carp_changed) || die "problem opening $iface_carp_changed\n";
                                        print FILE ("changed");
                                        close FILE;
                                        $critical{$interface} = $status;
                                        $counter++;
                                }
                        }
                        else {
                                open (FILE, '>', $iface_carp_status) || die "problem opening $iface_carp_status\n";
                                print FILE ($status);
                                close FILE;
                                $ok{$interface} = $status;
                                $counter++;
                        }
                }
        }
}

if (%critical) {
        print("CRITICAL - ");
        for (sort(keys %critical)) {
                print("$_ is $critical{$_} ");
        }
        print("\n");
        exit 1;
}
elsif (%ok) {
        print("OK - ");
        for (sort(keys %ok)) {
                print("$_ is $ok{$_} ");
        }
        print("\n");
        exit 0;
}
