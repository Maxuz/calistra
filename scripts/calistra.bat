@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@rem ##########################################################################
@rem
@rem                     Calistra script
@rem
@rem ##########################################################################

@rem Variables
set "SOURCE_DIR=%cd%"
set "WORK_DIR=%SOURCE_DIR%\work_dir"

@rem Java variables
set "JAVA_ARC_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jdk_x64_windows_hotspot_17.0.6_10.zip"
set "JAVA_FILE_ZIP=openjdk.tar.gz"
set "JDK_DIR=%WORK_DIR%\jdk-17.0.6+10"

@rem Spring variable
set "SPRING_VER=6.0.4"
set "SPRING_FILE_ZIP=v%SPRING_VER%.zip"
set "SPRING_ZIP_URL=https://github.com/spring-projects/spring-framework/archive/refs/tags/%SPRING_FILE_ZIP%"

@rem todo set dir name
set "SPRING_DIR="


:is_directory
set "IS_DIRECTORY="
if exist "%~1\" (set "IS_DIRECTORY=true")
if defined IS_DIRECTORY (exit /b 0) else (exit /b 1)

:prepare_working_directory
echo "Preparing the working directory: [%1]"

call :is_directory "%1"
if %errorlevel% EQU 0 (
  for /d %%d in ("%1\*") do rd /s /q "%%~d"
  for /f "delims=" %%f in ('dir /b /a-d "%1" ^| findstr /v /i /c:"%JAVA_FILE_ZIP%" /c:"%SPRING_FILE_ZIP%"') do del /f "%%~f"
) else (md "%1")

:download_file
echo "Downloading file from: [%~1], to [%~2\%~3]"

:: todo remove
:: powershell -command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2\%~3')"
powershell -Command "Invoke-WebRequest %~1 -OutFile %~2\%~3"

:extract_from_zip
echo "Unzipping file: [%~2\%~3]"

powershell -command "Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory('%~2\%~3', '%~1')"


@rem starting execution

@rem prepare working directory
call :prepare_working_directory "%WORK_DIR%"

@rem Download and unzip Java JDK
if not exist "%WORK_DIR%\%JAVA_FILE_ZIP%" (
  call :download_file "%JAVA_ARC_URL%" "%WORK_DIR%" "%JAVA_FILE_ZIP%"
)
call :extract_from_zip "%WORK_DIR%" "%JAVA_FILE_ZIP%"

@rem Download and unzip spring framework
if not exist "%WORK_DIR%\%SPRING_FILE_ZIP%" (
  call :download_file "%SPRING_ZIP_URL%" "%WORK_DIR%" "%SPRING_FILE_ZIP%"
)
call :extract_from_zip "%WORK_DIR%" "%SPRING_FILE_ZIP%"


cd "%SPRING_DIR%" || exit /b 1
set JAVA_HOME=%JDK_DIR%

@rem Run Gradle for the first time to download all dependencies
start /wait "%CD%\gradlew.bat --quiet clean compile"

@rem Starting tests
set "TEST_RESULT="

for /l %%i in (0,1,0) do (
  echo Starting test #%%i
  set "START=!time: =0!"

  start /wait "%CD%\gradlew.bat --quiet --no-build-cache --no-configuration-cache --parallel clean test"

  set "END=!time: =0!"
  set /a "ELAPSED=(1%END:~0,2%-100)*3600000 + (1%END:~3,2%-100)*60000 + (1%END:~6,2%-100)*1000 + (1%END:~9%-100) - ((1%START:~0,2%-100)*3600000 + (1%START:~3,2%-100)*60000 + (1%START:~6,2%-100)*1000 + (1%START:~9%-100))"
  set "TEST_RESULT=!TEST_RESULT! !ELAPSED!"
  echo Test #%%i finished
)

echo(
echo ####################################################
echo(
echo Test execution complete. Results for each iteration:
set /a "SUM=0"
set /a "TOTAL=0"
for %%i in (%TEST_RESULT%) do (
  set /a "SUM+=%%i"
  set /a "TOTAL+=1"
  echo #!TOTAL!: %%i ms
)
set /a "AVG=SUM/TOTAL"
echo Average time is: !AVG! ms
exit /b 0
