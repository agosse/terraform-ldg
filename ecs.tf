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

data "aws_iam_role" "ecs_service_role" {
  name = "ecsServiceRole"
}

resource "aws_appautoscaling_target" "ecs" {
  max_capacity = 6
  min_capacity = 1
  resource_id  = "service/cluster/api"
  role_arn     = "${data.aws_iam_role.ecs_service_role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "CPU"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "service/cluster/api"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 50
  }
  depends_on = ["aws_appautoscaling_target.ecs"]
}
