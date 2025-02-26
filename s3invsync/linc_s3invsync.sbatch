#!/bin/bash
#SBATCH --job-name=smart_job
#SBATCH --partition=ou_bcs_normal
#SBATCH --time=11:30:00   # Between 11 and 12 hours
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --mail-user=lincbrain@mit.edu
#SBATCH --mail-type=BEGIN,END,FAIL

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

OUTPUT_DIR="$HOME/slurm_logs/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

# Redirect standard output and error manually since SBATCH can't use runtime variables
exec > >(tee -a "$OUTPUT_DIR/job_output_$TIMESTAMP.txt") 2> >(tee -a "$OUTPUT_DIR/job_error_$TIMESTAMP.txt" >&2)

# Find an available node within `ou_bcs_normal` that meets time requirements
# ...probably unnecessary, but included to make sure that the node is consistent since MIT Engaging is changing often
SELECTED_NODE=$(sinfo --format="%P %N %T %l" | awk '
function time_to_minutes(t) {
    split(t, a, ":");
    return (length(a) == 3) ? (a[1] * 60 + a[2]) : a[1];
}
$1 == "ou_bcs_normal" && time_to_minutes($4) >= 660 && time_to_minutes($4) <= 720 && $3 ~ /idle|mix/ {print $2; exit}')

if [ -z "$SELECTED_NODE" ]; then
    echo "No available idle or mixed nodes in ou_bcs_normal with an 11-12 hour time limit. Exiting."
    exit 1
fi

echo "Selected node: $SELECTED_NODE"

echo "Setting up AWS CLI..."
AWS_CLI_DIR="$HOME/aws-cli-temp"
mkdir -p "$AWS_CLI_DIR"
cd "$AWS_CLI_DIR"

python3 -m venv aws-cli-venv
source aws-cli-venv/bin/activate
pip install --upgrade pip
pip install awscli jq
aws configure list
aws --version
aws sts get-caller-identity

echo "AWS credentials successfully retrieved."

aws s3 ls s3://mgh-neuroglancer/

## Cleanup AWS CLI
deactivate6
rm -rf "$AWS_CLI_DIR"

echo "Running linc_s3invsync job at $TIMESTAMP..."

cargo install s3invsync

s3invsync --allow-new-nonempty --ok-errors all s3://linc-brain-mit-staging-us-east-2/linc-brain-mit-staging-us-east-2/staging-configuration /orcd/data/linc/001/s3lincbrain/