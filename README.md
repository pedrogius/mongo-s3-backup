# mongo-s3-backup

This docker image is used to backup a MongoDB database to an S3 bucket. It uses the `mongodump` command to backup the database and the `aws` command to upload the backup to an S3 bucket.

It also keeps a set number of backups in the S3 bucket and deletes the oldest ones. The default is 10 backups, but it can be changed by setting the `NUM_VERSIONS_TO_KEEP` environment variable.

It was built to be used with digital ocean spaces, but it should work with any S3 compatible storage.
