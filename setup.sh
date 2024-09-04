# Setup script

CUDA_VERSION=12.4
INFERENCE_DEVICE=cpu

# Get operating system (Linux/Darwin)
OPERATING_SYSTEM=$(uname)

# Get CPU architecture (x86_64/arm64)
CPU_ARCHITECTURE=$(uname -m)

# Conda env name
CONDA_ENV=oc_external

# Usage function
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --device=<DEVICE>"
    echo "      Specify the device for inference."
    echo "      Values:"
    echo "          cpu: CPU"
    echo "          cuda: NVIDIA GPU (CUDA)"
    echo "          rocm: AMD GPU (ROCm 6.1)"
    echo "      Default: cpu"
    echo "      Note: CUDA and ROCm are only supported on Linux"
    echo ""
    echo "  --cuda_version=<CUDA_VERSION>"
    echo "      Specify the CUDA version for inference."
    echo "      Values:"
    echo "          11.8: CUDA 11.8"
    echo "          12.1: CUDA 12.1"
    echo "          12.4: CUDA 12.4"
    echo "      Default: 12.4"
    echo "      Note: This option is only applicable when --device=cuda"
    echo ""
    echo "  -h, --help"
    echo "      Show this help message and exit."
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        --device=*)
            INFERENCE_DEVICE="${arg#*=}"
            shift
            ;;
        --cuda_version=*)
            CUDA_VERSION="${arg#*=}"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Invalid argument: $arg"
            usage
            exit 1
            ;;
    esac
done

# Validate inference device
if [ $INFERENCE_DEVICE != "cpu" ] && [ $INFERENCE_DEVICE != "cuda" ] && [ $INFERENCE_DEVICE != "rocm" ]; then
    echo "Invalid inference device"
    exit 1
fi

# Validate CUDA version
if [ $INFERENCE_DEVICE == "cpu" ]; then
    CUDA_VERSION=""
elif [ $INFERENCE_DEVICE == "cuda" ]; then
    # Make sure CUDA version is one of the supported versions (11.8 / 12.1 / 12.4)
    if [ $CUDA_VERSION != "11.8" ] && [ $CUDA_VERSION != "12.1" ] && [ $CUDA_VERSION != "12.4" ]; then
        echo "Invalid CUDA version"
        exit 1
    fi
fi


# Setup miniconda if it doesn't exist
if [ ! -d "$(pwd)/miniconda" ]; then
    # Remove old installation script
    rm miniconda.sh

    # Download and install miniconda for the current operating system
    if [ $OPERATING_SYSTEM == "Darwin" ]; then
        if [ $CPU_ARCHITECTURE == "x86_64" ]; then
            wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O miniconda.sh
        elif [ $CPU_ARCHITECTURE == "arm64" ]; then
            wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -O miniconda.sh
        else
            echo "Unsupported CPU architecture for miniconda3"
            exit 1
        fi
    elif [ $OPERATING_SYSTEM == "Linux" ]; then
        if [ $CPU_ARCHITECTURE == "x86_64" ]; then
            wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
        elif [ $CPU_ARCHITECTURE == "arm64" ]; then
            wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -O miniconda.sh
        else
            echo "Unsupported CPU architecture for miniconda3"
            exit 1
        fi
    else
        echo "Unsupported operating system"
        exit 1
    fi

    # Stop if download failed
    if [ ! -f miniconda.sh ]; then
        echo "Miniconda download failed"
        exit 1
    fi

    bash miniconda.sh -b -p "$(pwd)/miniconda"

    # Stop if installation failed
    if [ $? -ne 0 ]; then
        echo "Miniconda installation failed"
        exit 1
    fi

    # Remove installation script
    rm miniconda.sh
fi

# Stop if miniconda is missing
if [ ! -d "$(pwd)/miniconda" ]; then
    echo "Miniconda folder is missing"
    exit 1
fi

# Activate miniconda
source "$(pwd)/miniconda/bin/activate"

# If it doesn't exist create conda environment with Python 3.11
if [ ! -d "$(pwd)/miniconda/envs/$CONDA_ENV" ]; then
    conda create -n $CONDA_ENV python=3.11 -y

    # Exit if conda environment creation failed
    if [ $? -ne 0 ]; then
        echo "Conda environment creation failed"
        exit 1
    fi
fi

# Activate the conda environment
source "$(pwd)/miniconda/bin/activate" $CONDA_ENV

# Exit if conda environment activation failed
if [ $? -ne 0 ]; then
    echo "Conda environment activation failed"
    exit 1
fi

# Install pytorch for the specified device (cpu/cuda/rocm)
if [ $INFERENCE_DEVICE == "cpu" ]; then
    conda install pytorch torchvision torchaudio cpuonly -c pytorch
elif [ $INFERENCE_DEVICE == "cuda" ]; then
    conda install -y pytorch torchvision torchaudio pytorch-cuda=$CUDA_VERSION -c pytorch -c nvidia
elif [ $INFERENCE_DEVICE == "rocm" ]; then
    python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1
else
    echo "Invalid inference device"
    exit 1
fi

# Exit if pytorch installation failed
if [ $? -ne 0 ]; then
    echo "PyTorch installation failed"
    exit 1
fi

# If using CUDA, install CUDA and cuDNN stuff via conda
if [ $INFERENCE_DEVICE == "cuda" ]; then
    conda install -y nvidia/label/cuda-$CUDA_VERSION::cuda cudnn=8.9.2.26 -c nvidia -c nvidia/label/cuda-$CUDA_VERSION
fi

# Exit if CUDA installation failed
if [ $? -ne 0 ]; then
    echo "CUDA installation failed"
    exit 1
fi

# Install other dependencies
python -m pip install "fastapi[standard]" transformers pillow huggingface_hub flash_attn einops timm faster-whisper

# Downgrade ctranslate2 if using CUDA 11.8 (allows FasterWhisper to use GPU with CUDA 11.8)
if [ $CUDA_VERSION == "11.8" ]; then
    python -m pip install --force-reinstall ctranslate2==3.24.0
fi

# Exit if other dependencies installation failed
if [ $? -ne 0 ]; then
    echo "Other dependencies installation failed"
    exit 1
fi
