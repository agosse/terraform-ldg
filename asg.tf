data "aws_ami" "ecs_optimised" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn-ami-2018.03.h-amazon-ecs-optimized"]
  }
}

data "template_file" "user_data" {
  template = "${file("templates/user_data.tpl")}"
  vars = {
    ecs_cluster = "${aws_ecs_cluster.cluster.name}"
  }
}

resource "aws_launch_configuration" "asg" {
  image_id                    = "${data.aws_ami.ecs_optimised.id}"
  instance_type               = "${var.ecs_cluster_instance_type}"
  security_groups             = ["${aws_default_security_group.default.id}", "${aws_security_group.admin_ssh.id}"]
  associate_public_ip_address = true
  iam_instance_profile        = "ecsInstanceRole"
  key_name                    = "${var.key_pair_name}"
  user_data                   = "${data.template_file.user_data.rendered}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_placement_group" "pg" {
  name     = "pg"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "ecs_instances" {
  name                      = "ecs-${aws_launch_configuration.asg.name}"
  min_size                  = 1
  desired_capacity          = 1
  max_size                  = 6
  health_check_grace_period = 300
  health_check_type         = "ELB"
  force_delete              = true
  placement_group           = "${aws_placement_group.pg.id}"
  launch_configuration      = "${aws_launch_configuration.asg.name}"
  vpc_zone_identifier       = ["${aws_subnet.subnet.*.id}"]
  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Role"
      value               = "ecsInstance"
      propagate_at_launch = true
    }
  ]
}
