data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block  = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}  

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.vpc.id}"
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_subnet" "subnet" {
    count             = "${length(data.aws_availability_zones.available.names)}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    vpc_id            = "${aws_vpc.vpc.id}"
    cidr_block        = "${cidrsubnet(aws_vpc.vpc.cidr_block, 3, count.index)}"
}

resource "aws_main_route_table_association" "rta" {
  vpc_id         = "${aws_vpc.vpc.id}"
  route_table_id = "${aws_route_table.rt.id}"
}
