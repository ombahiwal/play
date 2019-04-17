
provider "aws"{

    access_key = "AKIAVYQJJFT4KCOF6YPD"
    secret_key = "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"
    region = "us-east-1"

}

resource "aws_default_vpc_dhcp_options" "dhcp" {
  
  netbios_name_servers = ["10.0.0.0", "10.0.1.0"]
  netbios_node_type = "one"
  
  tags = {
    Name = "New DHCP Option Set"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = "vpc-093f091e847217a4c"
  dhcp_options_id = "${aws_vpc_dhcp_options.new_dhcp.id}"
}

