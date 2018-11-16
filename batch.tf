data "aws_iam_policy_document" "ecs_instance_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "ecs_instance_role"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

data "aws_iam_policy_document" "aws_batch_service_role" {
  statement {
    actions       = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_batch_service_role" {
  assume_role_policy = "${data.aws_iam_policy_document.aws_batch_service_role.json}"
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = "${aws_iam_role.aws_batch_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "batch" {
  compute_environment_name = "batch"
  compute_resources {
    instance_role      = "${aws_iam_instance_profile.ecs_instance_role.arn}"
    instance_type      = ["c4.large"]
    max_vcpus          = 16
    min_vcpus          = 0
    security_group_ids = ["${aws_default_security_group.default.id}"]
    subnets            = ["${aws_subnet.subnet.*.id}"]
    type               = "EC2"
  }
    
  service_role = "${aws_iam_role.aws_batch_service_role.arn}"
  type         = "MANAGED"
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
  
}

resource "aws_batch_job_queue" "q" {
  name                 = "q"
  state                = "ENABLED"
  priority             = 1
  compute_environments = ["${aws_batch_compute_environment.batch.arn}"]
}
