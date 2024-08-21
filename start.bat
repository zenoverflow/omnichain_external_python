@echo off

REM Start script

REM Conda env name
set CONDA_ENV=oc_external

REM Exit if miniconda is missing
if not exist "%cd%\miniconda" (
    echo Miniconda folder is missing
    exit /b 1
)

REM Activate miniconda
call "%cd%\miniconda\Scripts\activate.bat" %CONDA_ENV%

REM Exit if conda environment activation failed
if %errorlevel% neq 0 (
    echo Conda environment activation failed
    exit /b 1
)

REM Start app and forward arguments
python server.py %*