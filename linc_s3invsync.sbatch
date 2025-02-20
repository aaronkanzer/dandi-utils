#!/bin/bash
#SBATCH --job-name=smart_job
#SBATCH --partition=ou_bcs_normal
#SBATCH --time=11:30:00   # Between 11 and 12 hours
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

# Generate a timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Define output directory and create it
OUTPUT_DIR="$HOME/slurm_logs/$TIMESTAMP"
mkdir -p "$OUTPUT_DIR"

# Redirect standard output and error manually since SBATCH can't use runtime variables
exec > >(tee -a "$OUTPUT_DIR/job_output_$TIMESTAMP.txt") 2> >(tee -a "$OUTPUT_DIR/job_error_$TIMESTAMP.txt" >&2)

# Find an available node within `ou_bcs_normal` that meets time requirements
# Probably unnecessary, but included to make sure that the node is consistent since MIT Engaging is changing often
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
# Create a temporary directory for AWS CLI installation
AWS_CLI_DIR="$HOME/aws-cli-temp"
mkdir -p "$AWS_CLI_DIR"
cd "$AWS_CLI_DIR"

# Install AWS CLI using Python virtual environment
python3 -m venv aws-cli-venv
source aws-cli-venv/bin/activate
pip install --upgrade pip
pip install awscli jq

# Verify AWS CLI installation
aws --version

# Fetch AWS credentials from Secrets Manager (Replace `my-slurm-key` with your actual secret name)
#AWS_SECRET_NAME="my-slurm-key"
#SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id "$AWS_SECRET_NAME" --query "SecretString" --output text)
#
## Parse AWS credentials
#export AWS_ACCESS_KEY_ID=$(echo "$SECRET_JSON" | jq -r .AWS_ACCESS_KEY_ID)
#export AWS_SECRET_ACCESS_KEY=$(echo "$SECRET_JSON" | jq -r .AWS_SECRET_ACCESS_KEY)
#export AWS_DEFAULT_REGION="us-east-1"

# Check if credentials were retrieved
#if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
#    echo "Failed to retrieve AWS credentials!"
#    exit 1
#fi
#
#echo "AWS credentials successfully retrieved."
#
## Run AWS command (Example: List an S3 bucket)
#aws s3 ls s3://your-bucket-name/
#
## Cleanup AWS CLI (optional)
#deactivate
#rm -rf "$AWS_CLI_DIR"

echo "Running linc_s3invsync job at $TIMESTAMP..."