@echo off

set CUDA_VERSION=12.4
set INFERENCE_DEVICE=cpu

set CONDA_ENV=oc_external

REM Usage function
:usage
echo Usage: %0 [options]
echo Options:
echo   --device=<DEVICE>
echo       Specify the device for inference.
echo       Values:
echo           cpu: CPU
echo           cuda: NVIDIA GPU (CUDA)
echo       Default: cpu
echo.
echo   --cuda_version=<CUDA_VERSION>
echo       Specify the CUDA version for inference.
echo       Values:
echo           11.8: CUDA 11.8
echo           12.1: CUDA 12.1
echo           12.4: CUDA 12.4
echo       Default: 12.4
echo       Note: This option is only applicable when --device=cuda
echo.
echo   -h, --help
echo       Show this help message and exit.
goto :eof

REM Parse arguments
:parse_arguments
setlocal enabledelayedexpansion
for %%i in (%*) do (
    set "arg=%%i"
    if "!arg:~0,9!"=="--device=" (
        set "INFERENCE_DEVICE=!arg:~9!"
    ) else if "!arg:~0,15!"=="--cuda_version=" (
        set "CUDA_VERSION=!arg:~15!"
    ) else if "!arg!"=="-h" (
        call :usage
        exit /b 0
    ) else if "!arg!"=="--help" (
        call :usage
        exit /b 0
    ) else (
        echo Invalid argument: %%i
        call :usage
        exit /b 1
    )
)
endlocal & set INFERENCE_DEVICE=%INFERENCE_DEVICE% & set CUDA_VERSION=%CUDA_VERSION%
goto :validate_device

REM Validate inference device
:validate_device
if "%INFERENCE_DEVICE%" neq "cpu" if "%INFERENCE_DEVICE%" neq "cuda" (
    echo Invalid inference device
    exit /b 1
)
goto :validate_cuda_version

REM Validate CUDA version
:validate_cuda_version
if "%INFERENCE_DEVICE%"=="cpu" (
    set CUDA_VERSION=
) else if "%INFERENCE_DEVICE%"=="cuda" (
    REM Make sure CUDA version is one of the supported versions (11.8 / 12.1 / 12.4)
    if "%CUDA_VERSION%" neq "11.8" if "%CUDA_VERSION%" neq "12.1" if "%CUDA_VERSION%" neq "12.4" (
        echo Invalid CUDA version
        exit /b 1
    )
)
goto :setup_miniconda

REM Setup miniconda if it doesn't exist
:setup_miniconda
if not exist "%cd%\miniconda" (
    REM Remove old installation script
    del miniconda.bat

    REM Download and install miniconda for Windows
    powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe', 'miniconda.exe')"
    
    REM Stop if download failed
    if not exist miniconda.exe (
        echo Miniconda download failed
        exit /b 1
    )

    REM Install miniconda silently
    miniconda.exe /S /D="%cd%\miniconda"

    REM Stop if installation failed
    if not exist "%cd%\miniconda" (
        echo Miniconda installation failed
        exit /b 1
    )

    REM Remove installation script
    del miniconda.exe
)
goto :check_miniconda

REM Check if miniconda is missing
:check_miniconda
if not exist "%cd%\miniconda" (
    echo Miniconda folder is missing
    exit /b 1
)
goto :activate_miniconda

REM Activate miniconda
:activate_miniconda
call "%cd%\miniconda\Scripts\activate.bat"

REM Create conda environment with Python 3.11
conda create -n %CONDA_ENV% python=3.11 -y

REM Exit if conda environment creation failed
if not "%errorlevel%"=="0" (
    echo Conda environment creation failed
    exit /b 1
)
goto :activate_conda_env

REM Activate the conda environment
:activate_conda_env
call "%cd%\miniconda\Scripts\activate.bat" %CONDA_ENV%

REM Exit if conda environment activation failed
if not "%errorlevel%"=="0" (
    echo Conda environment activation failed
    exit /b 1
)
goto :install_pytorch

REM Install pytorch for the specified device (cpu/cuda)
:install_pytorch
if "%INFERENCE_DEVICE%"=="cpu" (
    conda install pytorch torchvision torchaudio cpuonly -c pytorch -y
) else if "%INFERENCE_DEVICE%"=="cuda" (
    conda install pytorch torchvision torchaudio cudatoolkit=%CUDA_VERSION% -c pytorch -c nvidia -y
) else (
    echo Invalid inference device
    exit /b 1
)

REM Exit if pytorch installation failed
if not "%errorlevel%"=="0" (
    echo PyTorch installation failed
    exit /b 1
)
goto :install_dependencies

REM Install other dependencies
:install_dependencies
python -m pip install "fastapi[standard]" transformers pillow huggingface_hub
python -m pip install flash_attn einops timm

REM Exit if other dependencies installation failed
if not "%errorlevel%"=="0" (
    echo Other dependencies installation failed
    exit /b 1
)
goto :eof
