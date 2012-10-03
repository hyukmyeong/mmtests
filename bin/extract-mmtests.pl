#!/usr/bin/perl
# extract-mmtests.pl - Extract results from an MM Tests directory
# 
# Different benchmark frameworks collect and report data differently. To
# analyse the data it is necessary to extract the raw performance figures.
# This program simplifies this task for this framework. At its most basic
# usage it takes a directory as a parameter and prints the most relevant
# metric of interest.
#
# Copyright: SUSE Labs, 2012
# Author:    Mel Gorman, 2012

use FindBin qw($Bin);
use lib "$Bin/lib";

use Getopt::Long;
use Pod::Usage;
use VMR::Report;
use MMTests::Extract;
use MMTests::ExtractFactory;
use MMTests::Monitor;
use MMTests::MonitorFactory;
use strict;

# Option variable
my ($opt_verbose);
my ($opt_help, $opt_manual);
my ($opt_reportDirectory, $opt_monitor);
my ($opt_printHeader, $opt_printPlot, $opt_printSummary, $opt_printType, $opt_printExtra);
my ($opt_subheading);
my ($opt_name, $opt_benchmark);
GetOptions(
	'verbose|v'		=> \$opt_verbose,
	'help|h'		=> \$opt_help,
	'--print-type'		=> \$opt_printType,
	'--print-header'	=> \$opt_printHeader,
	'--print-plot'		=> \$opt_printPlot,
	'--print-summary'	=> \$opt_printSummary,
	'--print-extra'		=> \$opt_printExtra,
	'--print-monitor=s'	=> \$opt_monitor,
	'--sub-heading=s'	=> \$opt_subheading,
	'n|name=s'		=> \$opt_name,
	'b|benchmark=s'		=> \$opt_benchmark,
	'manual'		=> \$opt_manual,
	'directory|d=s'		=> \$opt_reportDirectory,
);
setVerbose if $opt_verbose;
pod2usage(-exitstatus => 0, -verbose => 0) if $opt_help;
pod2usage(-exitstatus => 0, -verbose => 2) if $opt_manual;

# Sanity check directory
if (! -d $opt_reportDirectory) {
	printWarning("Report directory $opt_reportDirectory does not exist or was not specified.");
	pod2usage(-exitstatus => -1, -verbose => 0);
}
# If monitors are requested, extract that and exit
if (defined $opt_monitor) {
	my $monitorFactory = MMTests::MonitorFactory->new();
	my $monitorModule;
	eval {
		$monitorModule = $monitorFactory->loadModule($opt_monitor, $opt_reportDirectory);
	} or do {
		printWarning("Failed to load module for monitor $opt_monitor\n$@");
		exit(-1);
	};

	$monitorModule->extractReport($opt_reportDirectory, $opt_name, $opt_benchmark);
	$monitorModule->printFieldHeaders() if $opt_printHeader;
	$monitorModule->printReport();
	exit(0);
}

# Instantiate a handler of the requested type for the benchmark
my $extractFactory = MMTests::ExtractFactory->new();
my $extractModule;
eval {
	# Make a guess at the sub-directory name if one is not specified
	if ($opt_name ne "") {
		$opt_reportDirectory = "$opt_reportDirectory/$opt_benchmark-$opt_name";
	}
	$extractModule = $extractFactory->loadModule($opt_benchmark, $opt_reportDirectory);
} or do {
	printWarning("Failed to load module for benchmark $opt_benchmark\n$@");
	exit(-1);
};

# Just print the type if asked
if ($opt_printType) {
	$extractModule->printDataType();
	exit;
}

# Extract data from the benchmark itself and print whatever was requested
$extractModule->extractReport($opt_reportDirectory, $opt_name);
if ($opt_printPlot) {
	$extractModule->printPlotHeaders() if $opt_printHeader;
	$extractModule->printPlot($opt_subheading);
} elsif ($opt_printExtra) {
	$extractModule->printExtraHeaders() if $opt_printHeader;
	$extractModule->printExtra($opt_subheading);
} elsif ($opt_printSummary) {
	$extractModule->printSummaryHeaders() if $opt_printHeader;
	$extractModule->printSummary($opt_subheading);
} else {
	$extractModule->printFieldHeaders() if $opt_printHeader;
	$extractModule->printReport();
}

# Below this line is help and manual page information
__END__
=head1 NAME

extract-mmtests.pl - Extract results from an MM Tests result directory

=head1 SYNOPSIS

extract-mmtest [options]

 Options:
 -d, --directory	Work log directory to extract data from
 -n, --name		Title for the series if tests given to run-mmtests.sh
 -b, --benchmark	Benchmark to extract data for
 -v, --verbose		Verbose output
 --print-header		Print a header
 --print-summary	Summarise the data
 --print-extra		Print secondary data collected by the benchmark
 --print-monitor	Print information related to a monitor
 --print-plot		Print in a format suitable for consumption by gnuplot
 --sub-heading		Analyse just a sub-heading of the data, see manual page
 --manual		Print manual page
 --help			Print help message

=head1 OPTIONS

=over 8

=item B<-d, --directory>

Specifies the directory containing results generated by MM Tests.

=item B<n, --name>

The name of the test series as supplied to run-mmtests.sh. This might have
been a kernel version for example.

=item B<b, --benchmark>

The name of the benchmark to extract data from. For example, if a given
test ran kernbench and sysbench and the sysbench results were required
then specify "-b sysbench".

=item B<--print-type>

Print what type of metric the benchmark produces.

=item B<--print-header>

Print a header that briefly describes what each of the fields are.

=item B<--print-summary>

Summarise the data depending on the type. For CPUTime data for example it
will print the four columns User, Sys, Elapsed and CPU with four rows for
the min, mean, stddev and max values for each of those columns.

=item B<--print-extra>

Print additional information collected by the benchmark. Some benchmarks
like dbench4 have a primary set of data such as throughput and latency
while running the benchmark. It also reports the average and max latency
of the commands sent to the server but this cannot be sanely represented
with the main data. Use --print-extra in cases like this to see.

=item B<--print-monitor>

MM Tests gathers additional information with monitors that can also be
extracted. Some are always available and are coarse such as how long
the tests run. Others have to be enabled from the config file before
the benchmark runs.

=item B<--print-plot>

Print data suitable for plotting with. The exact format this takes will
depend on the type of data being extracted. It may be necessary to specify
--sub-heading.

=item B<--sub-heading>

For certain operation a sub-heading is required. For example, when extracting
CPUTime data and plotting it, it is necessary to specify if User, Sys,
Elapsed or CPU time is being plotted. In general --print-header can be
used to get a lot of the headings to pass to --sub-heading.

=item B<--help>

Print a help message and exit

=item B<-v, --verbose>

Be verbose in the output.

=back

=head1 DESCRIPTION

No detailed description available.

=head1 AUTHOD

Written by Mel Gorman <mgorman@suse.de>

=head1 REPORTING BUGS

Report bugs to the author.

=cut
