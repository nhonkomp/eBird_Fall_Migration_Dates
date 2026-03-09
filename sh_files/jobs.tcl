# This script creates slurm sbatch scripts for running Nora's
# ebird departure analysis.  The script must be used to generate
# an intermediate data file that can then be run to create or submit
# jobs via slurm.  The process entails:
#
# 1) create a database index (ebird-departure.db) from a group of csv files in a folder:
#
#    tclsh jobs.tcl -csvpath ./path/to/csv/files ebird-departure.db
#
# 2) print the sbatch files to stdout for debugging, based on a constraint:
#
#    tclsh jobs.tcl -where "alpha='amekes'" ebird-departure.db
#
# 3) write the sbatch files to a folder (must exist):
#    
#    tclsh jobs.tcl -where "alpha='amekes'" -write ./sbatch-scripts ebird-departure.db
#
# 4) submit jobs via the script
#
#    tclsh jobs.tcl -where "alpha='amekes'" -submit ebird-departure.db
#
# The constraint specied after the -where flag can apply constraints to cell, year,
# or alpha.  It can also be applied to more than one colum:
#
#    tclsh jobs.tcl -where "alpha='amekes' AND year>=2020" ebird-departure.db
#
# Other flags include:
#    -email (override norahonkomp@boisestate.edu for failure emails)
#    -queue (override short for the queue to submit the job to)
#
#Nora's notes:
# To submit all sbatch scripts- for x in $(ls ./sbatch-scripts/*); do sbatch $x; done
#
lappend auto_path {/bsuscratch/norahonkomp/ebird_departure_analysis/pkg/lib/tcllib1.21}
lappend auto_path {/bsuscratch/norahonkomp/ebird_departure_analysis/pkg/lib/sqlite3.41.2}

package require csv
package require sqlite3

proc lindex_panic {lst idx} {
	set n [llength $lst]
	if {$idx >= $n || $idx < 0} {
		error "index out of range: $idx"
	}
	return [lindex $lst $idx]
}

proc help {} {
  puts "tclsh jobs.tcl"
  puts "\t-csvpath path (import data from folder named in path)"
  puts "\t-email email (set the email for slurm notifications)"
  puts "\t-queue queue (use the named queue in the submission)"
  puts "\t-submit (submit the job using sbatch)"
  puts "\t-where sql (use sql as the WHERE clause to subset the submissions)"
  puts "\t-write path (path to write sbatch scripts to, overrides -submit)"
  puts "\tdbfile (file to read and write run metadata to)"
  exit 0
}

set template {#!/bin/bash
#SBATCH -J $alpha-$cell-$year
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=$email
#SBATCH -o $logs/$alpha-$cell-$year-%j.log
#SBATCH -N 1
#SBATCH --cpus-per-task 4
#SBATCH -p $queue
#SBATCH -t 2:00:00
cd $workdir
source $ebirdenv
$rscript 12_gams_halfmax.R -cell $cell -year $year -alpha $alpha $csvname
}

# set with command line options
set csvpath {}
set dbname {}
set where {}
set email {kyleshannon@boisestate.edu}
set queue {short}
set sbatch cat
set write {}

# set manually
set logs {/bsuscratch/kyle/nora/parallel/logs}
set workdir {/bsuscratch/kyle/nora/parallel/scripts}
set ebirdenv {~/nora.env}
# should be fine for both
set rscript {/cm/shared/software/spack/opt/spack/linux-centos7-cascadelake/gcc-12.1.0/r-4.2.2-7at2r2ejr7hheltu5nz5sczgipc7f2pk/bin/Rscript}

# nora's
set email {norahonkomp@boisestate.edu}
set logs {/bsuscratch/norahonkomp/ebird_departure_analysis/logs}
set workdir {/bsuscratch/norahonkomp/ebird_departure_analysis/scripts}
set ebirdenv {~/ebird.env}

set i 0
while {$i < $argc} {
	set arg [lindex_panic $argv $i]
	if {$arg == {-email}} {
		incr i
		set email [lindex_panic $argv $i]
	} elseif {$arg == {-queue}} {
		incr i
		set queue [lindex_panic $argv $i]
	} elseif {$arg == {-where}} {
		incr i
		set where [lindex_panic $argv $i]
	} elseif {$arg == {-submit}} {
		set sbatch {sbatch}
	} elseif {$arg == {-csvpath}} {
    incr i
		set csvpath [lindex_panic $argv $i]
	} elseif {$arg == {-write}} {
    incr i
		set write [lindex_panic $argv $i]
	} elseif {$arg == {-help}} {
    help
	} elseif {$dbname == {}} {
		set dbname $arg
	}
	incr i
}

if {$write != {} && $sbatch == {sbatch}} {
  puts "cannot write sbatch files and submit, choose one"
  exit 1
}

puts "opening $dbname..."
sqlite3 db $dbname

if {$csvpath != {}} {
	db eval {
		DROP TABLE IF EXISTS jobs;
		CREATE TABLE jobs(alpha TEXT, year INTEGER, cell INTEGER, csvname TEXT, UNIQUE(alpha, year, cell, csvname));
		PRAGMA journal_mode=off;
		PRAGMA synchronous=off;
	}

	set csvs [glob "$csvpath/*.csv"]
	db eval {BEGIN;}
	foreach c $csvs {
		set base [lindex [file split $c] end]
		set abs [file normalize $c]
		puts -nonewline "reading $base..."
		flush stdout
		set alpha [regexp -inline {_[a-z]{6}[0-9]?_} $c]
		set alpha [string trim $alpha {_}]
		set fin [open $c]
		gets $fin line
		set i 0
		while {[gets $fin line] >= 0} {
			set tkns [csv::split $line]
			set cell [lindex $tkns end]
			set year [lindex $tkns 7]
			db eval {
				INSERT OR IGNORE INTO jobs VALUES(:alpha, :year, :cell, $abs);
			}
		}
		close $fin
		puts " done."
		flush stdout
	}
	db eval {COMMIT;}
}
set work {
	set script [subst $template]
  if {$write != {}} {
    set fout [open [file join $write "12_$alpha-$cell-$year.sbatch"] {w}]
    puts $fout $script
    close $fout
  } else {
    set output [exec $sbatch << $script]
    puts $output
  }
}

if {$where == {}} {
	db eval {
		SELECT alpha, year, cell, csvname FROM jobs;
	} {
		eval $work
	}
} else {
	db eval "SELECT alpha, year, cell, csvname FROM jobs WHERE $where;" {
		eval $work
	}
}

db close
