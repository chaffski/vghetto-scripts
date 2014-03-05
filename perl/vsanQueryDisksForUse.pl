#!/usr/bin/perl -w
# Copyright (c) 2009-2014 William Lam All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author or contributors may not be used to endorse or
#    promote products derived from this software without specific prior
#    written permission.
# 4. Consent from original author prior to redistribution

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# William Lam
# www.virtuallyghetto.com

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;

# define custom options for vm and target host
my %opts = (
   'cluster' => {
      type => "=s",
      help => "Name of vSphere VSAN Cluster",
      required => 1,
   },
);

$SIG{__DIE__} = sub{Util::disconnect()};

# read and validate command-line parameters 
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

my $cluster = Opts::get_option("cluster");

my $cluster_view = Vim::find_entity_view(view_type => 'ComputeResource', filter => { 'name' => $cluster});
unless($cluster_view) {
       	Util::disconnect();
       	print "Error: Unable to find vSphere Cluster " . $cluster . "\n";
      	exit 1;
}

my $host_views = Vim::get_views(mo_ref_array => $cluster_view->host, properties => ['name','configManager.vsanSystem']);
foreach my $host_view (@$host_views) {
	&getHostStatus($host_view);
}

Util::disconnect();

sub getHostStatus {
	my ($host) = @_;

	my $vsanSys = Vim::get_view(mo_ref => $host->{'configManager.vsanSystem'});

	my $vsanStatus;
	eval {
		print "Host: " . $host->name . "\n";
		$vsanStatus = $vsanSys->QueryDisksForVsan();
		foreach (@$vsanStatus) {
			print "\tDisk: " . $_->disk->canonicalName . "\n";
			print "\tSSD: " . ($_->disk->ssd ? "yes" : "no") . "\n";
			print "\tState: " . $_->state . "\n\n";
		}
		print "\n";
	};
	if($@) {
		print "Error: " . $@ . "\n";
		Util:disconnect();
		exit 1;
	}
}
