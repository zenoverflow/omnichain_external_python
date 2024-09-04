@echo off

set CUDA_VERSION=12.4
set INFERENCE_DEVICE=cpu

:: Get operating system (Linux/Darwin)
for /f "delims=" %%i in ('uname') do set OPERATING_SYSTEM=%%i

:: Get CPU architecture (x86_64/arm64)
for /f "delims=" %%i in ('uname -m') do set CPU_ARCHITECTURE=%%i

:: Conda env name
set CONDA_ENV=oc_external

:: Usage function
:usage
echo Usage: %0 [options]
echo Options:
echo   --device=<DEVICE>
echo       Specify the device for inference.
echo       Values:
echo           cpu: CPU
echo           cuda: NVIDIA GPU (CUDA)
echo           rocm: AMD GPU (ROCm 6.1)
echo       Default: cpu
echo       Note: CUDA and ROCm are only supported on Linux
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

:: Parse arguments
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
        echo Invalid argument: !arg!
        call :usage
        exit /b 1
    )
)
endlocal & set INFERENCE_DEVICE=%INFERENCE_DEVICE% & set CUDA_VERSION=%CUDA_VERSION%
goto :validate_inference_device

:: Validate inference device
:validate_inference_device
if not "%INFERENCE_DEVICE%"=="cpu" if not "%INFERENCE_DEVICE%"=="cuda" if not "%INFERENCE_DEVICE%"=="rocm" (
    echo Invalid inference device
    exit /b 1
)
goto :validate_cuda_version

:: Validate CUDA version
:validate_cuda_version
if "%INFERENCE_DEVICE%"=="cpu" (
    set CUDA_VERSION=
) else if "%INFERENCE_DEVICE%"=="cuda" (
    if not "%CUDA_VERSION%"=="11.8" if not "%CUDA_VERSION%"=="12.1" if not "%CUDA_VERSION%"=="12.4" (
        echo Invalid CUDA version
        exit /b 1
    )
)
goto :setup_miniconda

:: Setup miniconda if it doesn't exist
:setup_miniconda
if not exist "%cd%\miniconda" (
    :: Remove old installation script
    del /f miniconda.bat

    :: Download and install miniconda for the current operating system
    if "%OPERATING_SYSTEM%"=="Darwin" (
        if "%CPU_ARCHITECTURE%"=="x86_64" (
            powershell -command "(New-Object System.Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh', 'miniconda.sh')"
        ) else if "%CPU_ARCHITECTURE%"=="arm64" (
            powershell -command "(New-Object System.Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh', 'miniconda.sh')"
        ) else (
            echo Unsupported CPU architecture for miniconda3
            exit /b 1
        )
    ) else if "%OPERATING_SYSTEM%"=="Linux" (
        if "%CPU_ARCHITECTURE%"=="x86_64" (
            powershell -command "(New-Object System.Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh', 'miniconda.sh')"
        ) else if "%CPU_ARCHITECTURE%"=="arm64" (
            powershell -command "(New-Object System.Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh', 'miniconda.sh')"
        ) else (
            echo Unsupported CPU architecture for miniconda3
            exit /b 1
        )
    ) else (
        echo Unsupported operating system
        exit /b 1
    )

    :: Stop if download failed
    if not exist miniconda.sh (
        echo Miniconda download failed
        exit /b 1
    )

    call miniconda.sh -b -p "%cd%\miniconda"

    :: Stop if installation failed
    if not !errorlevel! equ 0 (
        echo Miniconda installation failed
        exit /b 1
    )

    :: Remove installation script
    del /f miniconda.sh
)
goto :check_miniconda_folder

:: Stop if miniconda is missing
:check_miniconda_folder
if not exist "%cd%\miniconda" (
    echo Miniconda folder is missing
    exit /b 1
)
goto :activate_miniconda

:: Activate miniconda
:activate_miniconda
call "%cd%\miniconda\Scripts\activate.bat"

:: If it doesn't exist create conda environment with Python 3.11
if not exist "%cd%\miniconda\envs\%CONDA_ENV%" (
    conda create -n %CONDA_ENV% python=3.11 -y

    :: Exit if conda environment creation failed
    if not !errorlevel! equ 0 (
        echo Conda environment creation failed
        exit /b 1
    )
)
goto :activate_conda_env

:: Activate the conda environment
:activate_conda_env
call "%cd%\miniconda\Scripts\activate.bat" %CONDA_ENV%

:: Exit if conda environment activation failed
if not !errorlevel! equ 0 (
    echo Conda environment activation failed
    exit /b 1
)
goto :install_pytorch

:: Install pytorch for the specified device (cpu/cuda/rocm)
:install_pytorch
if "%INFERENCE_DEVICE%"=="cpu" (
    conda install pytorch torchvision torchaudio cpuonly -c pytorch
) else if "%INFERENCE_DEVICE%"=="cuda" (
    conda install -y pytorch torchvision torchaudio pytorch-cuda=%CUDA_VERSION% -c pytorch -c nvidia
) else if "%INFERENCE_DEVICE%"=="rocm" (
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1
) else (
    echo Invalid inference device
    exit /b 1
)

:: Exit if pytorch installation failed
if not !errorlevel! equ 0 (
    echo PyTorch installation failed
    exit /b 1
)
goto :install_cuda_dependencies

:: If using CUDA, install CUDA and cuDNN stuff via conda
:install_cuda_dependencies
if "%INFERENCE_DEVICE%"=="cuda" (
    conda install -y nvidia/label/cuda-%CUDA_VERSION%::cuda cudnn=8.9.2.26 -c nvidia -c nvidia/label/cuda-%CUDA_VERSION%
)

:: Exit if CUDA installation failed
if not !errorlevel! equ 0 (
    echo CUDA installation failed
    exit /b 1
)
goto :install_other_dependencies

:: Install other dependencies
:install_other_dependencies
python -m pip install "fastapi[standard]" transformers pillow huggingface_hub flash_attn einops timm faster-whisper

:: Downgrade ctranslate2 if using CUDA 11.8 (allows FasterWhisper to use GPU with CUDA 11.8)
if "%CUDA_VERSION%"=="11.8" (
    python -m pip install --force-reinstall ctranslate2==3.24.0
)

:: Exit if other dependencies installation failed
if not !errorlevel! equ 0 (
    echo Other dependencies installation failed
    exit /b 1
)
