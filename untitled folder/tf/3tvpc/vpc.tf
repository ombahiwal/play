provider "aws"{

    access_key = "AKIAVYQJJFT4KCOF6YPD"
    secret_key = "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"
    region = "us-east-1"

}
resource "aws_vpc" "T3-VPC" {
  cidr_block       = "10.0.0.0/19"
  tags = {
    Name = "T3 Demo VPC"
  }
}

resource "aws_subnet" "web-subnet" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.0.0/21"

  tags = {
    Name = "Subnet-WEB"
  }
}

resource "aws_subnet" "app-subnet" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.8.0/21"

  tags = {
    Name = "Subnet-APP"
  }
}

resource "aws_subnet" "db-subnet" {
  vpc_id     = "${aws_vpc.T3-VPC.id}"
  cidr_block = "10.0.16.0/21"

  tags = {
    Name = "Subnet-DB"
  }
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

  # Web Sec Group
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
    cidr_blocks = ["10.0.0.0/21"]
  }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.0.16.0/21"]
    }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.16.0/21"]
  }

  vpc_id = "${aws_vpc.T3-VPC.id}"
}

# App sec group
resource "aws_security_group" "3-tier-security-group-db" {
  name        = "3-tierSg-DB"
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
        cidr_blocks = ["10.0.8.0/21"]
    }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.16.0/21"]
  }

  vpc_id = "${aws_vpc.T3-VPC.id}"
}

resource "aws_instance" "web" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.web-subnet.id }" # using a public subnet for external availability
  associate_public_ip_address = true                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "WEbInstance"
  }

vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-web.id }"] # attaching security group

}

resource "aws_instance" "app" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.app-subnet.id }" # using a public subnet for external availability
  associate_public_ip_address = false                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "APPInstance"
  }

    vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-app.id }"] # attaching security group


}

resource "aws_instance" "db" {
  ami = "ami-0a313d6098716f372"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.db-subnet.id }" # using a public subnet for external availability
  associate_public_ip_address = false                               # adding a public IP to it, so we can access from outside

  tags {
    BuiltWith = "terraform"
    Name      = "DBInstance"
  }

  vpc_security_group_ids = ["${ aws_security_group.3-tier-security-group-db.id }"] # attaching security group

}

resource "aws_instance" "nat" {
  ami = "ami-00a9d4a05375b2763"

  instance_type = "t2.micro"
  key_name      = "ec2-key-pair"

  source_dest_check           = false
  subnet_id                   = "${ aws_subnet.web-subnet.id }" # using a public subnet for external availability
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

resource "aws_route_table_association" "web-association" {
  subnet_id      = "${aws_subnet.web-subnet.id}"
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

resource "aws_route_table_association" "app-association" {
  subnet_id      = "${aws_subnet.app-subnet.id}"
  route_table_id = "${aws_route_table.RT-APP-DB.id}"
}

resource "aws_route_table_association" "db-association" {
  subnet_id      = "${aws_subnet.db-subnet.id}"
  route_table_id = "${aws_route_table.RT-APP-DB.id}"
}