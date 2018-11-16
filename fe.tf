resource "aws_s3_bucket" "docroot" {
  bucket        = "${var.fe_bucket_id}"
  acl           = "private"
  force_destroy = "true"
  website {
      index_document = "index.html"
  }

  versioning {
      enabled = false
  }
}

locals {
    docroot_origin_id = "AngularOrigin"
}

data "aws_iam_policy_document" "docroot" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.docroot.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.docroot.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.docroot.arn}"]
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.docroot.iam_arn}"]
    }
  }
}


resource "aws_s3_bucket_policy" "docroot" {
  bucket = "${aws_s3_bucket.docroot.id}"
  policy = "${data.aws_iam_policy_document.docroot.json}"
}

resource "aws_cloudfront_distribution" "docroot" {
  aliases = [ "www.${var.zone_name}" ]
  default_root_object = "index.html"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  enabled = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    target_origin_id = "${local.docroot_origin_id}"
  }

  origin = {
    domain_name = "${aws_s3_bucket.docroot.bucket_regional_domain_name}"
    origin_id = "${local.docroot_origin_id}"
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.docroot.cloudfront_access_identity_path}"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${var.fe_cert_arn}"
    ssl_support_method = "sni-only"
  }

}

resource "aws_cloudfront_origin_access_identity" "docroot" {
    comment = "Access Identity for Angular."
}

