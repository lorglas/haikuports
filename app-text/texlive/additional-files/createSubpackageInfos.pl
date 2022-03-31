#!/bin/perl
# Copyright 2021, Joachim Mairböck <j.mairboeck@gmail.com>
# Distributed under the terms of the MIT license.

# Helper script to generate the package metadata definitions for the texlive subpackages
# usage:
# 	perl -I $sourceDir/tlpkg createSubpackageInfos.pl <tlpdbroot> > subpackageInfos.recipe
#
#	<tlpdbroot> is the root of the TeXLive package database, containing tlpkg/texlive.tlpdb.
#		It also needs the texmf-dist directory to work.
#		After these have been symlinked to $sourceDir (by the BUILD function in the recipe),
#		$sourceDir can be used inside the haikuporter chroot.
#		Alternatively, after the installation of the texlive package,
#		/boot/system/data/texlive can be used.
#
# This script uses the TeXLive perl modules, therefore it needs $sourceDir/tlpkg in @INC.

use strict;
use warnings;

use TeXLive::TLPDB;

print "# This file has been generated by createSubpackageInfos.pl\n\n";

my $tlpdb = TeXLive::TLPDB->new(root => $ARGV[0]);
my @collections = $tlpdb->collections();

for my $collectionPkgName (@collections) {
	my $collection = substr $collectionPkgName, 11;
	my $collectionPkg = $tlpdb->get_package($collectionPkgName);
	my $shortdesc = $collectionPkg->shortdesc();
	my $longdesc = $collectionPkg->longdesc();
	if (length $shortdesc >= 48) { # SUMMARY must not exceed 80 characters in total
		$shortdesc = substr($shortdesc, 0, 46) . "…";
	}
	if ($shortdesc =~ /\.$/) { # SUMMARY must not end in a '.'
		$shortdesc = substr($shortdesc, 0, -1);
	}
	$shortdesc =~ s'`'\`'g; # escape '`' characters
	$longdesc =~ s'`'\`'g if $longdesc;
	my @depends = $collectionPkg->depends();
	my @runfiles;
	my @docfiles;
	my @srcfiles;
	for my $depName (@depends) {
		my $depPkg = $tlpdb->get_package($depName);
		push @runfiles, $depPkg->runfiles();
		push @docfiles, $depPkg->docfiles();
		push @srcfiles, $depPkg->srcfiles();
	}
	if (@runfiles) {
		print "SUMMARY_$collection=\"TeX Collection: $shortdesc\"\n";
		print "DESCRIPTION_$collection=\"$longdesc\"\n" if $longdesc;
		print "PROVIDES_$collection=\"\n";
		print "\ttexlive_$collection = \$portVersion\n";
		print "\t\"\n";
		print "REQUIRES_$collection=\"\n";
		print "\thaiku\n";
		print "\ttexlive == \$portVersion base\n";
		for my $dep (@depends) {
			print "\ttexlive_", substr($dep, 11), "\n" if $dep =~ /^collection-/;
		}
		print "\t\"\n";
		print "REQUIRES_full+=\"\n";
		print "\ttexlive_$collection\n";
		print "\t\"\n";
		print "POST_INSTALL_SCRIPTS_$collection=\"\$relativePostInstallDir/texlive_postinstall.sh\"\n";
		print "subpackages+=($collection)\n";
	}
	if (@docfiles) {
		print "SUMMARY_${collection}_doc=\"TeX Collection: $shortdesc (documentation)\"\n";
		print "DESCRIPTION_${collection}_doc=\"$longdesc\"\n" if $longdesc;
		print "PROVIDES_${collection}_doc=\"\n";
		print "\ttexlive_${collection}_doc = \$portVersion\n";
		print "\t\"\n";
		print "REQUIRES_${collection}_doc=\"\n";
		print "\thaiku\n";
		print "\ttexlive == \$portVersion base\n";
		print "\t\"\n";
		print "REQUIRES_full_doc+=\"\n";
		print "\ttexlive_${collection}_doc\n";
		print "\t\"\n";
		print "subpackages+=(${collection}_doc)\n";
	}
	if (@srcfiles) {
		print "SUMMARY_${collection}_source=\"TeX Collection: $shortdesc (source files)\"\n";
		print "DESCRIPTION_${collection}_source=\"$longdesc\"\n" if $longdesc;
		print "PROVIDES_${collection}_source=\"\n";
		print "\ttexlive_${collection}_source = \$portVersion\n";
		print "\t\"\n";
		print "REQUIRES_${collection}_source=\"\n";
		print "\thaiku\n";
		print "\ttexlive == \$portVersion base\n";
		print "\t\"\n";
		print "REQUIRES_full_source+=\"\n";
		print "\ttexlive_${collection}_source\n";
		print "\t\"\n";
		print "subpackages+=(${collection}_source)\n";
	}
}