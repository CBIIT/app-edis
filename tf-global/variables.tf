variable "s3bucket" {
  type = string
  description = "S3 Bucket name containing api-edis-tf-state/<<oracledb-layer zip file name>"
}
variable "layer-file" {
  type = string
  description = "File name containing oracledb layer files in zipped format"
  default = "oracledb-layer.zip"
}
