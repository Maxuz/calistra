#!/bin/bash
#
# Copyright 2023 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "############################################################################"
echo ""
echo "                                Calistra                                    "
echo ""
echo "############################################################################"
echo ""

# Variables
SOURCE_DIR=$(pwd)
WORK_DIR=$SOURCE_DIR/work_dir

# Java variable
# MacOs x64
#JAVA_ARC_URL=https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jdk_x64_mac_hotspot_17.0.6_10.tar.gz

# MacOs aarch64
#JAVA_ARC_URL=https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.6_10.tar.gz

JAVA_FILE_ARC="openjdk.tar.gz"
JDK_DIR="$WORK_DIR/jdk-17.0.6+10"

# Spring variables
SPRING_VER="6.0.4"
SPRING_FILE_ZIP="v$SPRING_VER.zip"
SPRING_ZIP_URL="https://github.com/spring-projects/spring-framework/archive/refs/tags/$SPRING_FILE_ZIP"

# Gradle
GRADLE_TARGET_TASK="test"
GRADLE_OPTS="--quiet --no-build-cache --no-configuration-cache"

# It's not true single thread/core execution, we just trying to limit Gradle as much as possible
NO_PARALLEL_GRADLE_OPTS="--no-parallel --max-workers 1"
PARALLEL_GRADLE_OPTS="--parallel"

is_directory() {
  if [ -d "$1" ]; then
    return 0
  else
    return 1
  fi
}

prepare_working_directory() {
  local DIR=$1
  echo "Preparing the working directory: [$DIR]"

  if is_directory "$DIR"; then
    find "$DIR" -maxdepth 1 ! -path "$DIR" -type d -exec rm -rf {} \;
    find "$DIR" -maxdepth 1 ! \( -name "$JAVA_FILE_ARC" -o -name "$SPRING_FILE_ZIP" \) -type f -exec rm -f {} \;
  else
    mkdir "$DIR"
  fi
}

download_file() {
  local URL=$1
  local DEST_DIR=$2
  local FILE_NAME=$3

  echo "Downloading file from: [$URL], to [$DEST_DIR/$FILE_NAME]"

  curl --silent -o "$DEST_DIR/$FILE_NAME" -L "$URL"
}

extract_from_tar() {
  local DIR=$1
  local FILE=$2

  echo "Extracting files from: [$FILE]"

  cd "$DIR" || exit 1
  tar -xzf "$FILE"
  cd - 1>/dev/null || exit 1
}

extract_from_zip() {
  local DIR=$1
  local FILE=$2

  echo "Unzipping file: [$FILE]"

  cd "$DIR" || exit 1
  unzip -q "$FILE"
  cd - 1>/dev/null || exit 1
}

find_spring_directory() {
  local DIR=$1
  local RESULT
  RESULT=$(find "$DIR" -maxdepth 1 -type d -name "spring-framework-*" -print | head -1)

  echo "$RESULT"
}

run_gradle() {
  local DIR=$1
  local JAVA_HOME=$2
  local OPTS=$3
  local TASKS=$4
  local CMD

  cd "$DIR" || exit 1

  CMD="env JAVA_HOME=$JAVA_HOME /bin/sh $(pwd)/gradlew $OPTS $TASKS"
  # For debug
  #  echo "Running command: [$CMD]"
  ${CMD} 2>/dev/null
  cd - 1>/dev/null || exit 1
}

if [ -z "$JAVA_ARC_URL" ]; then
  echo "Please uncomment the JAVA_ARC_URL variable in the begging of the script"
  exit 1
fi

# prepare working directory
prepare_working_directory "$WORK_DIR"

# Download and unzip Java JDK
if [ ! -f "$WORK_DIR/$JAVA_FILE_ARC" ]; then
  download_file "$JAVA_ARC_URL" "$WORK_DIR" "$JAVA_FILE_ARC"
fi
extract_from_tar "$WORK_DIR" "$JAVA_FILE_ARC"

# Download and unzip spring framework
if [ ! -f "$WORK_DIR/$SPRING_FILE_ZIP" ]; then
  download_file "$SPRING_ZIP_URL" "$WORK_DIR" "$SPRING_FILE_ZIP"
fi

extract_from_zip "$WORK_DIR" "$SPRING_FILE_ZIP"

SPRING_DIR=$(find_spring_directory "$WORK_DIR")

if [ -n "${SPING_DIR}" ]; then
  echo "Spring framework directory is not found"
  exit 1
fi

# Run Gradle for the first time to download all dependencies
run_gradle "$SPRING_DIR" "$JDK_DIR" "$GRADLE_OPTS" "clean compileJava"

declare -a TEST_RESULT

for ((i = 0; i < 3; i++)); do
  echo "Starting test #$i"
  START=$(date +%s)
  run_gradle "$SPRING_DIR" "$JDK_DIR" "$GRADLE_OPTS $PARALLEL_GRADLE_OPTS" "clean $GRADLE_TARGET_TASK"
  EXEC_TIME=$(($(date +%s) - START))
  TEST_RESULT[$i]=$EXEC_TIME
  echo "Test #$i finished"
done

echo ""
echo "####################################################"
echo ""
echo "Test execution is completed. Results for each iteration:"
for i in "${!TEST_RESULT[@]}"; do
  echo "#$i: ${TEST_RESULT[$i]}s"
done

# Calculating average time
TOTAL=0
SUM=0
for i in "${TEST_RESULT[@]}"; do
  ((SUM += $i))
  ((TOTAL++))
done
echo "Average time is: $((SUM / TOTAL)) s"

exit 0
