# Calistra

## Description
There are a lot of CPU benchmarks and I think that the vast majority of them do not show performance for real world tasks. 
Moreover, some of them are using special optimization for a CPU or for a platform, what makes them unreliable,
in the case you want to see a real boost if you get the CPU.

I want to see CPU performance on task that a lot of software developers are facing every day. For this reason I took
one of the most popular programming language and one of the most popular framework for it - `Java` and `Spring Framework`.

There is a set of scripts for different OSs. Each script prepares all necessary environment (download JDK, Spring 
Framework source code, Gradle, etc.) and runs compilation and tests execution tasks three times. At the end, the script
prints results: time for each test and average execution time.

You can find test results on this page [test-results.md](test-results.md). Adding your results are more than welcome.

## How to
### Run script on Windows
Just run the `calistra.bat` file from the `scripts` directory.

### Run script on Linux
Just run the `calistra.sh` file from the `scripts` directory.

### Run script on MacOS
There is a special script for MacOS - `calistra-mac.sh` in the `scripts` directory. 

Before run the script you need to uncomment one of the `JAVA_ARC_URL` that is appropriate for your system.

Then you need to run the `calistra-mac.sh` script file.

## Disclaimer
I'm not a profession scriptwriter, so there are could be not optimal solutions. 
It's highly welcome to publish improvements for the scripts.

