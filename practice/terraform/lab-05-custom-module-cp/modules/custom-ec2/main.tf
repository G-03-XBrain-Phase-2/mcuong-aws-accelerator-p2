resource "aws_security_group" "cuong_sg" {
  name        = "${var.instance_name}-sg"
  vpc_id      = var.vpc_id
  description = "SG tao boi custom-ec2 module"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0 # port range
    to_port     = 0
    protocol    = "-1" # đại diện cho tất cả giao thức và phải đi kèm với from_port = 0 và to_port =0 (tất cả các cổng)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

resource "aws_instance" "cuong-ec2" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.cuong_sg.id]

  tags = {
    Name = var.instance_name
  }
}
