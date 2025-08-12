#!/bin/bash
#PBS -N SRS_L33_70B_Extract
#PBS -q iworkq
#PBS -l select=1:ncpus=48:mpiprocs=48:ngpus=2:mem=300gb
#PBS -l walltime=24:00:00
#PBS -o srs_l33_70b_output.o
#PBS -e srs_l33_70b_error.e

# ================================
#   PBS JOB START
# ================================
echo "[INFO] Job started on $(date)"
echo "[INFO] Running on host: $(hostname)"
echo "[INFO] Working directory: $PBS_O_WORKDIR"
echo "[INFO] Nodes allocated:"
cat "$PBS_NODEFILE"

# ================================
#   Change to Job Directory
# ================================
cd "$PBS_O_WORKDIR" || { echo "[ERROR] Cannot change to PBS_O_WORKDIR"; exit 1; }

# ================================
#   Virtual Environment Setup
# ================================
ENV_PATH="/home/drdlivv01/demo/packagesDemo/code_catalyst_lite/codeanalysis-env"
WHEELS_PATH="/home/drdlivv01/demo/packagesDemo/maam_llama_api_server/wheels"

if [ ! -d "$ENV_PATH" ]; then
    echo "[INFO] Creating virtual environment..."
    python3 -m venv "$ENV_PATH" || { echo "[ERROR] Failed to create venv"; exit 1; }
    source "$ENV_PATH/bin/activate"
    echo "[INFO] Installing dependencies..."
    pip install --no-index --find-links="$WHEELS_PATH" -r requirements.txt
else
    echo "[INFO] Activating existing virtual environment..."
    source "$ENV_PATH/bin/activate"
fi

# ================================
#   GPU Configuration
# ================================
export CUDA_VISIBLE_DEVICES=0,1
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments=True

if command -v nvidia-smi &>/dev/null; then
    echo "[INFO] GPU Status:"
    nvidia-smi
else
    echo "[WARN] nvidia-smi not found. CUDA may be missing."
fi

# ================================
#   Python Env Info
# ================================
echo "[INFO] Python version: $(python --version)"
echo "[INFO] Pip version: $(pip --version)"

# ================================
#   Run Inference Script
# ================================
SCRIPT_PATH="/home/drdlivv01/yesh/srs/l33_70b_instruct_gpu_srs.py"

if [ -f "$SCRIPT_PATH" ]; then
    echo "[INFO] Running inference script: $SCRIPT_PATH"
    python3 "$SCRIPT_PATH" > "output_$(date +%Y%m%d_%H%M%S).log" 2>&1
else
    echo "[ERROR] Inference script not found: $SCRIPT_PATH"
    exit 1
fi

# ================================
#   Clean Up
# ================================
deactivate
echo "[INFO] Job completed on $(date)"
