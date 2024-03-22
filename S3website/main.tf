resource "aws_s3_bucket" "demo-bucket" {
  bucket = var.my_bucket_name  # name of the S3 bucket
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.demo-bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.demo-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [ 
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
   ]

  bucket = aws_s3_bucket.demo-bucket.id
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "host_bucket_policy" {
  bucket = aws_s3_bucket.demo-bucket.id

  #Policy  JSON for allowing public read access
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement" : [
        {
            "Effect" : "Allow",
            "Principal" : "*",
            "Action" : "s3.GetObject",
            "Resource" : "arn:aws:s3:::${var.my_bucket_name}/*"
        }
    ]
  })
}

module "template-files" {
    source = "hashicorp/dir/template"
    
    base_dir = "${path.module}/web-files"
}

resource "aws_s3_bucket_website_configuration" "web-config" {
  bucket = aws_s3_bucket.demo-bucket.id

  #Configuration for the index document
  index_document {
    suffix = "index.html"
  }
}


resource "aws_s3_object" "bucket_files" {
  bucket = aws_s3_bucket.demo-bucket.id

  for_each = module.template-files.files
  key =  each.key
  content_type =  each.value.content_type

  source = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5
}