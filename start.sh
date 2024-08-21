# Start script

# Conda env name
CONDA_ENV=oc_external

# Exit if miniconda is missing
if [ ! -d "$(pwd)/miniconda" ]; then
    echo "Miniconda folder is missing"
    exit 1
fi

# Activate miniconda
source "$(pwd)/miniconda/bin/activate" $CONDA_ENV

# Exit if conda environment activation failed
if [ $? -ne 0 ]; then
    echo "Conda environment activation failed"
    exit 1
fi

# Start app and forward arguments
python server.py $@
