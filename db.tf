resource "aws_rds_cluster" "default" {
  cluster_identifier      = "aurora-cluster"
  engine_mode             = "serverless"
  availability_zones      = ["${data.aws_availability_zones.available.names}"]
  database_name           = "${var.database_name}"
  master_username         = "${var.database_user}"
  master_password         = "${var.database_pass}"
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  vpc_security_group_ids  = ["${aws_security_group.db.id}"]
  db_subnet_group_name = "${aws_db_subnet_group.default.name}"
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 256
    min_capacity             = 2
    seconds_until_auto_pause = 300
  }
}

resource "aws_db_subnet_group" "default" {
  subnet_ids = ["${aws_subnet.subnet.*.id}"]
}
