## Setup Steps on AWS Side

### Enable Versioning and Inventory Configuration Management

The following is example output from `aws s3api list-bucket-inventory-configurations --bucket <bucket-name-here>`

In the `OptionalFields` section, you can see the fields needed to properly handle a sync of the S3 bucket via `s3invsync`

```shell
{
    "InventoryConfigurationList": [
        {
            "Destination": {
                "S3BucketDestination": {
                    "AccountId": "151312473579",
                    "Bucket": "arn:aws:s3:::<bucket-name-here>",
                    "Format": "CSV"
                }
            },
            "IsEnabled": true,
            "Id": "versioned-s3invsync",
            "IncludedObjectVersions": "All",
            "OptionalFields": [
                "Size",
                "LastModifiedDate",
                "ETag",
                "IsMultipartUploaded",
                "ChecksumAlgorithm"
            ],
            "Schedule": {
                "Frequency": "Daily"
            }
        }
    ],
    "IsTruncated": false
}
```

### Issued a new user:

```
{
    "UserId": "AIDASGOXNDXVU6GU3SSNH",
    "Account": "151312473579",
    "Arn": "arn:aws:iam::151312473579:user/engaging-user"
}
```

with IAM policy attached:

```shell
{
    "Version": "2012-10-17",
    "Statement": [
        ...other stuff
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetObjectAttributes",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:ListBucketVersions"
            ],
            "Resource": [
                "arn:aws:s3:::your-bucket-name",
                "arn:aws:s3:::your-bucket-name/*"
            ]
        }
        ...
    ]
}
```

**Note:** Ensure that user is read-only!

### Setup credentials in Engaging

```shell
mkdir -p ~/.aws
cat > ~/.aws/credentials <<EOF
[default]
aws_access_key_id=<access_key>
aws_secret_access_key=<aws_secret_access_key>
EOF

cat > ~/.aws/config <<EOF
[default]
region=us-east-2
EOF
```

### Corresponding S3 bucket policy (for example)

```shell
{
    "Version": "2012-10-17",
    "Statement": [
        ...other stuff -- added the clause below
        {
            "Sid": "AllowUserAccess",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::151312473579:user/engaging-user"
            },
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetObjectVersion"
            ],
            "Resource": [
                "arn:aws:s3:::mgh-neuroglancer",
                "arn:aws:s3:::mgh-neuroglancer/*"
            ]
        },
        ...
    ]
}
```
