@echo off
setlocal enabledelayedexpansion

set CUDA_VERSION=12.4
set INFERENCE_DEVICE=cpu
set CONDA_ENV=oc_external

:: Parse arguments
:parse_arguments
if "%~1"=="" goto :main
if /i "%~1"=="--device" (
    set "INFERENCE_DEVICE=%~2"
    shift
) else if /i "%~1"=="--cuda_version" (
    set "CUDA_VERSION=%~2"
    shift
) else if "%~1"=="-h" (
    call :usage
    exit /b 0
) else if "%~1"=="--help" (
    call :usage
    exit /b 0
) else (
    echo Invalid argument: %~1
    call :usage
    exit /b 1
)
shift
goto :parse_arguments

:main
call :validate_inference_device
if errorlevel 1 exit /b 1
call :validate_cuda_version
if errorlevel 1 exit /b 1
call :setup_miniconda
if errorlevel 1 exit /b 1
call :create_conda_env
if errorlevel 1 exit /b 1
call :run_in_conda_env
exit /b 0

:: Usage function
:usage
echo Usage: %~nx0 [options]
echo Options:
echo   --device ^<DEVICE^>
echo       Specify the device for inference.
echo       Values:
echo           cpu: CPU
echo           cuda: NVIDIA GPU (CUDA)
echo       Default: cpu
echo       Note: CUDA is only supported on Windows with NVIDIA GPUs
echo.
echo   --cuda_version ^<CUDA_VERSION^>
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
exit /b 0

:: Validate inference device
:validate_inference_device
if /i not "%INFERENCE_DEVICE%"=="cpu" if /i not "%INFERENCE_DEVICE%"=="cuda" (
    echo Invalid inference device
    exit /b 1
)
exit /b 0

:: Validate CUDA version
:validate_cuda_version
if /i "%INFERENCE_DEVICE%"=="cpu" (
    set CUDA_VERSION=
) else if /i "%INFERENCE_DEVICE%"=="cuda" (
    if not "%CUDA_VERSION%"=="11.8" if not "%CUDA_VERSION%"=="12.1" if not "%CUDA_VERSION%"=="12.4" (
        echo Invalid CUDA version
        exit /b 1
    )
)
exit /b 0

:: Setup miniconda if it doesn't exist
:setup_miniconda
if not exist "%cd%\miniconda" (
    :: Download and install miniconda for Windows
    powershell -command "(New-Object System.Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe', 'miniconda.exe')"

    if not exist miniconda.exe (
        echo Miniconda download failed
        exit /b 1
    )

    start /wait "" miniconda.exe /S /D=%cd%\miniconda

    if not exist "%cd%\miniconda" (
        echo Miniconda installation failed
        exit /b 1
    )

    del /f miniconda.exe
)
exit /b 0

:: Create conda environment if it doesn't exist
:create_conda_env
if not exist "%cd%\miniconda\envs\%CONDA_ENV%" (
    call "%cd%\miniconda\Scripts\conda.exe" create -n %CONDA_ENV% python=3.11 -y
    if errorlevel 1 (
        echo Conda environment creation failed
        exit /b 1
    )
)
exit /b 0

:: Run commands in conda environment
:run_in_conda_env
call "%cd%\miniconda\Scripts\activate.bat" %CONDA_ENV%

:: Install pytorch for the specified device (cpu/cuda)
if /i "%INFERENCE_DEVICE%"=="cpu" (
    call conda install --update-all -y pytorch torchvision torchaudio cpuonly -c pytorch
) else if /i "%INFERENCE_DEVICE%"=="cuda" (
    call conda install --update-all -y pytorch torchvision torchaudio pytorch-cuda=%CUDA_VERSION% -c pytorch -c nvidia
) else (
    echo Invalid inference device
    exit /b 1
)
if errorlevel 1 (
    echo PyTorch installation failed
    exit /b 1
)

:: If using CUDA, install CUDA and cuDNN stuff via conda
if /i "%INFERENCE_DEVICE%"=="cuda" (
    call conda install --update-all -y nvidia/label/cuda-%CUDA_VERSION%.0::cuda cudnn=8.9.2.26 -c nvidia
    if errorlevel 1 (
        echo CUDA installation failed
        exit /b 1
    )
)

:: Install other dependencies
call python -m pip install --upgrade "fastapi[standard]" transformers pillow huggingface_hub einops timm faster-whisper

if errorlevel 1 (
    echo Other dependencies installation failed
    exit /b 1
)

if /i "%INFERENCE_DEVICE%"=="cuda" (
    if "%CUDA_VERSION%"=="11.8" (
        call python -m pip install --force-reinstall ctranslate2==3.24.0

        if errorlevel 1 (
            echo Other dependencies installation failed
            exit /b 1
        )
    )
)

call conda deactivate
exit /b 0
