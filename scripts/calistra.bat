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

@echo off
setlocal enabledelayedexpansion

@echo: 
@echo: 
@echo: 
@echo: 
@echo: 
@echo ##########################################################
@echo ####################               #######################
@echo ###########             Calistra         #################
@echo ####################               #######################
@echo ##########################################################
@echo: 
@echo: 
@echo: 
@echo: 
@echo: 


@rem Variables
set "SOURCE_DIR=%cd%"
set "RESULT_FILE=%SOURCE_DIR%\results.txt"
set "WORK_DIR=%SOURCE_DIR%\work_dir"

@rem Java variables
set "JAVA_ARC_URL=https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%%%%2B10/OpenJDK17U-jdk_x64_windows_hotspot_17.0.6_10.zip"
set "JAVA_FILE_ZIP=openjdk.zip"
set "JDK_DIR=%WORK_DIR%\jdk-17.0.6+10"

@rem Spring variable
set "SPRING_VER=6.0.4"
set "SPRING_FILE_ZIP=v6.0.4.zip"
set "SPRING_ZIP_URL=https://github.com/spring-projects/spring-framework/archive/refs/tags/v6.0.4.zip"
set "SPRING_DIR=%WORK_DIR%\spring-framework-6.0.4"

@echo Preparing working directory

if exist "%WORK_DIR%" (
  call :remove_dir "%JDK_DIR%"
  call :remove_dir "%SPRING_DIR%"
) else (
  md "%WORK_DIR%"
)

cd "%WORK_DIR%"

@echo Preparing Java

if not exist "%JAVA_FILE_ZIP%" (
  call :download_file "%JAVA_ARC_URL%" "%WORK_DIR%" "%JAVA_FILE_ZIP%"
)
@echo Extracting %JAVA_FILE_ZIP%
powershell -command "Expand-Archive -Path %WORK_DIR%\%JAVA_FILE_ZIP% -DestinationPath %WORK_DIR%"
set JAVA_HOME=%JDK_DIR%


@echo Preparing Spring framework
if not exist "%SPRING_FILE_ZIP%" (
  call :download_file "%SPRING_ZIP_URL%" "%WORK_DIR%" "%SPRING_FILE_ZIP%"
)

@echo Extracting %SPRING_FILE_ZIP%
powershell -command "Expand-Archive -Path %WORK_DIR%\%SPRING_FILE_ZIP% -DestinationPath %WORK_DIR%"

@echo Running first compilation to download all dependencies

cd %SPRING_DIR%

call gradlew.bat --quiet --no-build-cache --no-configuration-cache clean compileJava

@echo: 
@echo: 
@echo Starting tests ...
@echo: 
@echo: 

set "TEST_RESULT="

for /l %%i in (0,1,2) do (
  echo Starting test #%%i
  set "START=!time: =0!"

  call gradlew.bat --quiet --no-build-cache --no-configuration-cache clean test

  set "END=!time: =0!"

  set /a "ELAPSED=(1!END:~0,2!-100)*3600000 + (1!END:~3,2!-100)*60000 + (1!END:~6,2!-100)*1000 + (1!END:~9!-100) - ((1!START:~0,2!-100)*3600000 + (1!START:~3,2!-100)*60000 + (1!START:~6,2!-100)*1000 + (1!START:~9!-100))"

  set "TEST_RESULT=!TEST_RESULT! !ELAPSED!"

  echo Test #%%i finished in !ELAPSED! ms
)

call gradlew.bat --stop

@echo:
@echo:
@echo:
@echo:
@echo:
@echo:
@echo #################################################################
@echo:
@echo Test execution is completed. Results for each iteration:

set /a "SUM=0"
set /a "TOTAL=0"

@echo Test execution results: > %RESULT_FILE%

for %%i in (%TEST_RESULT%) do (
  set /a "SUM+=%%i"
  set /a "TOTAL+=1"
  @echo #!TOTAL!: %%i ms
  @echo #!TOTAL!: %%i ms >> !RESULT_FILE!
)

set /a "AVG=SUM/TOTAL"

@echo: 
@echo Average time is: !AVG! ms
@echo: >> %RESULT_FILE%
@echo Average time is: !AVG! ms >> %RESULT_FILE%

@echo:
@echo:
@echo:
@echo:
@echo:
@echo:
@pause

exit /b

:remove_dir
  if exist %1 (
    @echo Removing directory %1%
    RD /S /Q %1
  )
  exit /b 0

:download_file
  @echo Downloading file: [%1]
  powershell -Command "Invoke-WebRequest %1 -OutFile %~2\%~3"
  exit /b 0
