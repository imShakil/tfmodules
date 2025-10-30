resource "aws_key_pair" "ec2_ssh_key" {
  key_name   = var.ssh_key_pair["ssh_username"]
  public_key = file(var.ssh_key_pair["ssh_key_path"])

}

resource "aws_instance" "epkbk_ec2" {
  count                  = var.instance_number
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  key_name               = aws_key_pair.ec2_ssh_key.key_name

  tags = {
    Name = "${var.prefix}-ec2-instance-${count.index + 1}"
  }
}
