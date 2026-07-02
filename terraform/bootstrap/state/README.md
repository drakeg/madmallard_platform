# Terraform State Bootstrap

For the first pass, local state is simplest and free.

When ready, create an S3/DynamoDB backend for shared state locking. That adds minimal cost but is not necessary before there are multiple maintainers or automated applies.
