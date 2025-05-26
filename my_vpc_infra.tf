# Create vpc
resource "aws_vpc" "tt_vpc" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "tt_vpc"
  }
}


# Create internet gateway and attach to your vpc
resource "aws_internet_gateway" "tt_gw" {
  vpc_id = aws_vpc.tt_vpc.id

  tags = {
    Name = "tt_igw"
  }
}


## PUBLIC SUBNET DOINGS
# create a public subnet and attach it to the vpc
resource "aws_subnet" "tt_pub_sub" {
  vpc_id     = aws_vpc.tt_vpc.id
  cidr_block = "10.10.0.0/24"

  tags = {
    Name = "tt_pub_sub"
  }

  availability_zone = "eu-west-3a"
}


# Create a route table and tag it public
resource "aws_route_table" "tt_pub_rt" {
  vpc_id = aws_vpc.tt_vpc.id

  # The local routes are allowed by default

  # Add a route to the inernet gateway i.e any traffic can flow in and out via the igw
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tt_gw.id
  }

  tags = {
    Name = "tt_pub_rt"
  }
}

# Associate your public route table with your public subnet
resource "aws_route_table_association" "tt_pub_rt_a" {
  subnet_id      = aws_subnet.tt_pub_sub.id
  route_table_id = aws_route_table.tt_pub_rt.id
}



## PRIVATE SUBNET DOINGS
# Create private subnet and attach it to the vpc
resource "aws_subnet" "tt_priv_sub" {
  vpc_id     = aws_vpc.tt_vpc.id
  cidr_block = "10.10.1.0/24"

  tags = {
    Name = "tt_priv_sub"
  }

  availability_zone = "eu-west-3b" # This is another availability zone for resilience
}


# Create route table for the private subnet and attach it to your vpc
resource "aws_route_table" "tt_priv_rt" {
  vpc_id = aws_vpc.tt_vpc.id

  # The local routes are allowed by default

  # No route to the internet unless we create NAT gateway

  tags = {
    Name = "tt_priv_rt"
  }
}


# Associate the private route table to the private subnet
resource "aws_route_table_association" "tt_riv_rt_a" {
  subnet_id      = aws_subnet.tt_priv_sub.id
  route_table_id = aws_route_table.tt_priv_rt.id
}




## SPECIAL ORDER - CREATE SECURITY GROUP - Two portions of rice
resource "aws_security_group" "tt_pub_sg" {
  name        = "tt_pub_sg"
  description = "Allow ssh inbound traffic and All outbound traffic"
  vpc_id      = aws_vpc.tt_vpc.id

  tags = {
    Name = "tt_pub_sg"
  }
}

# Set ingress rule
resource "aws_vpc_security_group_ingress_rule" "tt_pub_sg_ing_rule" {
  security_group_id = aws_security_group.tt_pub_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Which ip range do we allw traffic to come from
  from_port         = 22          # i.e ssh access
  ip_protocol       = "tcp"       # ssh uses tcp protocol
  to_port           = 22          # Apparently, we must specify from and to while using tcp/udp
}

# Set egress rule
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tt_pub_sg.id
  cidr_ipv4         = "0.0.0.0/0" # Allow us traffic to everywhere. Awa o binu enikan
  ip_protocol       = "-1"        # All protocols and All ports
}

