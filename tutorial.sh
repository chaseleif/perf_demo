#! /usr/bin/env bash

set -e

testcmd="python -c"
testcmdargs="import tensorflow
print(tensorflow.__version__)"

goto() {
  eval "$(sed -n "/${1}:/{:a;n;p;ba}" $0 | grep -v ':$')"
  exit
}

showmenu() {
  read -p "
0) Display general perf info
1) Display perf help
2) Display perf list
3) Perform perf test
4) Show paranoia
5) Run perf stat
6) Run perf record
7) Run perf top
8) Other tools

else) quit

Enter your selection: " response
  case ${response} in
    0) start="start" ;;
    1) start="showhelp" ;;
    2) start="showlist" ;;
    3) start="perftest" ;;
    4) start="paranoia" ;;
    5) start="perfstat" ;;
    6) start="perfrecord" ;;
    7) start="perftop" ;;
    8) start="othertools" ;;
    *) start="end" ;;
  esac
}

docontinue() {
  read -p "${1}, or enter 'q' to quit or 's' to stop: " response
  [[ "${response}" =~ [qQ] ]] && exit 0
  [[ "${response}" =~ [sS] ]] && unset start
  return 0
}

start=""

showmenu
goto ${start}

start:
echo "https://perf.wiki.kernel.org/index.php/Tutorial"

echo "Perf is a profiler tool for Linux 2.6+ based systems that abstracts away CPU hardware differences in Linux performance measurements and presents a simple commandline interface. Perf is based on the perf_events interface exported by recent versions of the Linux kernel. This article demonstrates the perf tool through example runs. Output was obtained on a Ubuntu 11.04 system with kernel 2.6.38-8-generic results running on an HP 6710b with dual-core Intel Core2 T7100 CPU). For readability, some output is abbreviated using ellipsis ([...]).
"

docontinue "Continue with the \"perf help\""
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

showhelp:
echo "
$ perf help"
perf help

echo "We can get a list of events from the perf command
[Hardware (cache) event] items are monikers mapped are mapped to CPU events
[Kernel PMU] Performance Monitoring Unit items are values from the hardware
[STD event] are dtrace style parkers for instrumented programs
"

docontinue "Continue with the \"perf list\""
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

showlist:

echo "
$ perf list"
set +e
perf list
set -e

echo ""

docontinue "Continue with the \"perf test\""
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

perftest:

echo "
$ perf test"
perf test

echo "
Some items were skipped . . .
Either we don't have permissions or the item is unavailable
"

docontinue "Continue to check the paranoia setting"
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

paranoia:

./paranoia.sh

echo "We could add a perf_users group and workaround this issue if we want,
though unless you have multiple users there isn't much point, just use sudo
"

docontinue "Continue with a \"perf stat\""
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

perfstat:

read -p "
Run \"perf stat\"
0) Without options
1) With repeated measurements
2) With some named options
3) Same as option 2, but in processor-wide mode
4) 

Enter your selection: " response

case ${response} in
  1) opts="-r 5"
    ;;
  2) opts="-B -e l1d.replacement,cycle_activity.stalls_total,cycle_activity.cycles_l1d_miss,ild_stall.lcp"
    ;;
  3) opts="-B -e l1d.replacement,cycle_activity.stalls_total,cycle_activity.cycles_l1d_miss,ild_stall.lcp -a"
    ;;
  *) opts=""
esac

basecmd="perf stat ${opts}"

echo "$ ${basecmd} ${testcmd} \"${testcmdargs}\""

${basecmd} ${testcmd} "${testcmdargs}"

case ${response} in
  1) echo "It is possible to use perf stat to run the same test workload multiple times and get for each count, the standard deviation from the mean."
    ;;
  2) echo "l1d.replacement [Counts the number of cache lines replaced in L1 data cache]
cycle_activity.stalls_total [Total execution stalls]
cycle_activity.cycles_l1d_miss [Cycles while L1 cache miss demand load is outstanding]
ild_stall.lcp [Stalls caused by changing prefix length of the instruction]"
    ;;
  3) echo "Processor-wide mode
l1d.replacement [Counts the number of cache lines replaced in L1 data cache]
cycle_activity.stalls_total [Total execution stalls]
cycle_activity.cycles_l1d_miss [Cycles while L1 cache miss demand load is outstanding]
ild_stall.lcp [Stalls caused by changing prefix length of the instruction]"
    ;;
  4) echo "

https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3b-part-2-manual.html
Table 18-2. Association of Fixed-Function Performance Counters with Architectural Performance Events"
    ;;
  *) echo "With no events specified, perf stat collects the common events listed above.
Some are software events, such as context-switches, others are generic hardware events such as cycles.
After the hash sign, derived metrics may be presented, such as 'IPC' (instructions per cycle)."
    ;;
esac

echo "
There are additional options to alter output for reability by machine or person
"

read -p "Do another \"perf stat\"? (y/N) " response
if [[ "${response}" =~ [yY] ]] ; then
  goto perfstat
fi

docontinue "Continue with a \"perf record\""
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

perfrecord:

echo "By default, perf record operates in per-thread mode, with inherit mode enabled.
The simplest mode looks as follows, when executing a simple program that busy loops:

$ perf record ${testcmd} \"${testcmdargs}\""

rm -f perf.data
perf record ${testcmd} "${testcmdargs}"


read -p "
\"perf.data\" created, view the contents? (Y/n) " response
if ! [[ "${response}" =~ [nN] ]] ; then
  set +e
  perf script
  set -e
fi

echo "
WARNING: The number of reported samples is only an estimate.
It does not reflect the actual number of samples collected.
The estimate is based on the number of bytes written to the perf.data file and the minimal sample size.
But the size of each sample depends on the type of measurement.
Some samples are generated by the counters themselves but others are recorded to support symbol correlation during post-processing, e.g., mmap() information.
"

echo "To get an accurate number of samples for the perf.data file, it is possible to use the perf report command:"

echo "$ perf report -D -i perf.data | fgrep RECORD_SAMPLE | wc -l"
perf report -D -i perf.data | fgrep RECORD_SAMPLE | wc -l

docontinue "
Continue with a \"perf top\""
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

perftop:

if [ $(id -u) -ne 0 ] ; then
  echo "
Lack requirements to run \"perf top\" (run as sudo)"
else
  perf top
fi

docontinue "
Continue and show other tools in the perf suite"
if [ -z ${start} ] ; then
  showmenu
  goto ${start}
fi

othertools:

echo "
Other perf tools:"
echo "
PERF(1)                                                         perf Manual                                                        PERF(1)"
echo "
NAME
       perf - Performance analysis tools for Linux"
echo "
DESCRIPTION
       Performance counters for Linux are a new kernel-based subsystem that provide a framework for all things performance analysis. It
       covers hardware level (CPU/PMU, Performance Monitoring Unit) features and software features (software counters, tracepoints) as
       well."
echo "
SEE ALSO
       perf-stat(1), perf-top(1), perf-record(1), perf-report(1), perf-list(1)"
echo "
       perf-annotate(1),perf-archive(1),perf-arm-spe(1), perf-bench(1), perf-buildid-cache(1), perf-buildid-list(1), perf-c2c(1), perf-
       config(1), perf-data(1), perf-diff(1), perf-evlist(1), perf-ftrace(1), perf-help(1), perf-inject(1), perf-intel-pt(1), perf-
       iostat(1), perf-kallsyms(1), perf-kmem(1), perf-kvm(1), perf-lock(1), perf-mem(1), perf-probe(1), perf-sched(1), perf-script(1),
       perf-test(1), perf-trace(1), perf-version(1)"
echo "
perf 5.19-1                                                     2022-04-14                                                         PERF(1)
"

read -p "
This was the last item, return to the menu? (y/N) " response
if [[ "${response}" =~ [yY] ]] ; then
  showmenu
  goto ${start}
fi

end:

echo "
Goodbye o_O"