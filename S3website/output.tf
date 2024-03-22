output "website_url" {
    value = aws_s3_bucket_website_configuration.web-config.website_endpoint
    description = "My website UEL"
}