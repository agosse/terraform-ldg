data "aws_ecr_repository" "repo" {
  name = "${var.ecr_name}"
}

data "template_file" "container_definition" {
  template = "${file("templates/taskdef.tpl")}"
  vars = {
    ecr_uri = "${data.aws_ecr_repository.repo.repository_url}"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "cluster"
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.api.arn}"
  desired_count   = 1
  iam_role        = "ecsServiceRole"
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = "${aws_lb_target_group.tg.arn}"
    container_name   = "api"
    container_port   = 80
  }

  placement_constraints {
    type  = "memberOf"
    expression = "attribute:ecs.availability-zone in [${join(",",data.aws_availability_zones.available.names)}]"
  }

  depends_on = [
    "aws_lb_listener.http",
    "aws_lb_listener.https"
  ]
}

resource "aws_ecs_task_definition" "api" {
  family = "service"
  container_definitions = "${data.template_file.container_definition.rendered}"
}
