provider "aws"{

    access_key = "AKIAVYQJJFT4KCOF6YPD"
    secret_key = "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"
    region = "us-west-1"

}
resource "aws_vpc" "T3-VPC" {
  cidr_block       = "10.0.0.0/19"
  tags = {
    Name = "T3-VPC-tf-6subs"
  }
}

resource "aws_subnet" "web-subnet-1" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.0.0/22"
    availability_zone = "us-east-1a"
  tags = {
    Name = "Subnet-WEB-1"
  }
}

resource "aws_subnet" "web-subnet-2" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.4.0/22"
    availability_zone = "us-east-1b"
  tags = {
    Name = "Subnet-WEB-2"
  }
}

resource "aws_subnet" "app-subnet-1" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.8.0/22"
availability_zone = "us-east-1a"
  tags = {
    Name = "Subnet-APP-1"
  }
}
resource "aws_subnet" "app-subnet-2" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.12.0/22"
availability_zone = "us-east-1b"
  tags = {
    Name = "Subnet-APP-2"
  }
}

resource "aws_subnet" "db-subnet-1" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.16.0/22"
availability_zone = "us-east-1a"
  tags = {
    Name = "Subnet-DB-1"
  }
}
resource "aws_subnet" "db-subnet-2" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.20.0/22"
availability_zone = "us-east-1b"
  tags = {
    Name = "Subnet-DB-2"
  }
}

# DHCP options
resource "aws_vpc_dhcp_options" "t3-dhcp" {
  domain_name="mycompany.com"
  domain_name_servers=["10.0.31.10","10.0.31.11"]
  netbios_name_servers = ["10.0.31.10"]
  netbios_node_type=2
  tags = {
    Name = "VPC DHCP Option Set - 3t - 6sub"
  }
}
resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "${aws_vpc.T3-VPC.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.t3-dhcp.id}"
}




# security group to be attached to our instance
resource "aws_security_group" "3-tier-security-group-web" {
  name        = "3-tierSg-web"
  description = "3-tierSg for Web Instances"

  # allowing SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.T3-VPC.id}"
}

# App sec group
resource "aws_security_group" "3-tier-security-group-app" {
  name        = "3-tierSg-APP"
  description = "3-tierSg for App Instances"

  # allowing SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    #inbound from web subnet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/21"]
  }

#inbound from db subnet
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.0.16.0/21"]
    }
  
  #outbound to DB
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.16.0/21"]
  }
   #outbound to Web
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/21"]
  }

  vpc_id = "${aws_vpc.T3-VPC.id}"
}

# DB sec group
resource "aws_security_group" "3-tier-security-group-db" {
  name        = "3-tierSg-DB"
  description = "3-tierSg for DB Instances"

  # allowing SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# inbound from app subnet
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.0.8.0/21"]
    }
    #outbound to app subnet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.8.0/21"]
  }

  vpc_id = "${aws_vpc.T3-VPC.id}"
}

resource "aws_instance" "web1" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.web-subnet-1.id }" # using a public subnet for external availability
  associate_public_ip_address = true                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "WEbInstance-1"
  }

vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-web.id }"] # attaching security group

}

resource "aws_instance" "web2" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.web-subnet-2.id }" # using a public subnet for external availability
  associate_public_ip_address = true                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "WEbInstance-2"
  }

vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-web.id }"] # attaching security group

}

resource "aws_instance" "App1" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.app-subnet-1.id }" # using a public subnet for external availability
  associate_public_ip_address = true                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "AppInstance1"
  }

vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-web.id }"] # attaching security group

}

resource "aws_instance" "App2" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.app-subnet-2.id }" # using a public subnet for external availability
  associate_public_ip_address = false                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "APPInstance2"
  }

    vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-app.id }"] # attaching security group


}

resource "aws_instance" "db1" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.db-subnet-1.id }" # using a public subnet for external availability
  associate_public_ip_address = false                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "DBInstance1"
  }

  vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-db.id }"] # attaching security group

}

resource "aws_instance" "db2" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.db-subnet-2.id }" # using a public subnet for external availability
  associate_public_ip_address = false                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "DBInstance2"
  }

  vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-db.id }"] # attaching security group

}

resource "aws_instance" "nat" {
  ami = "ami-00a9d4a05375b2763"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.web-subnet-1.id }" # using a public subnet for external availability
  associate_public_ip_address = true                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "NATInstance"
  }
vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-web.id }"] # attaching security group
  

}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.T3-VPC.id}"

  tags = {
    Name = "IGW for T3"
  }
}
resource "aws_route_table" "RT-WEB" {
  vpc_id = "${aws_vpc.T3-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

  tags = {
    Name = "WEB-RT"
  }
}

resource "aws_route_table_association" "web-association-1" {
  subnet_id      = "${aws_subnet.web-subnet-1.id}"
  route_table_id = "${aws_route_table.RT-WEB.id}"
}

resource "aws_route_table_association" "web-association-2" {
  subnet_id      = "${aws_subnet.web-subnet-2.id}"
  route_table_id = "${aws_route_table.RT-WEB.id}"
}

resource "aws_route_table" "RT-APP-DB" {
  vpc_id = "${aws_vpc.T3-VPC.id}"
  route{
      cidr_block = "0.0.0.0/0"
      instance_id = "${aws_instance.nat.id}"
  }
  tags = {
    Name = "APP-DB-RT"
  }
}

resource "aws_route_table_association" "app-association-1" {
  subnet_id      = "${aws_subnet.app-subnet-1.id}"
  route_table_id = "${aws_route_table.RT-APP-DB.id}"
}
resource "aws_route_table_association" "app-association-2" {
  subnet_id      = "${aws_subnet.app-subnet-2.id}"
  route_table_id = "${aws_route_table.RT-APP-DB.id}"
}
resource "aws_route_table_association" "db-association-1" {
  subnet_id      = "${aws_subnet.db-subnet-1.id}"
  route_table_id = "${aws_route_table.RT-APP-DB.id}"
}

resource "aws_route_table_association" "db-association-2" {
  subnet_id      = "${aws_subnet.db-subnet-2.id}"
  route_table_id = "${aws_route_table.RT-APP-DB.id}"
}



# Create a new load balancer
resource "aws_elb" "test-elb" {
  name               = "test-terraform-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  subnets=["${aws_subnet.app-subnet-1.id}", "${aws_subnet.app-subnet-2.id}"]
  access_logs {
    bucket        = "logs-bucket-aws"
    interval      = 60
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#   listener {
#     instance_port      = 8000
#     instance_protocol  = "http"
#     lb_port            = 443
#     lb_protocol        = "https"
#     ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#   }

  health_check {
    healthy_threshold   = 8
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = ["${aws_instance.App1.id}", "${aws_instance.App2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "test-terraform-elb"
  }
}