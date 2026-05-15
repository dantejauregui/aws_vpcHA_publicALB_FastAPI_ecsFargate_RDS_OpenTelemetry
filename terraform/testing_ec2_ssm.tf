# resource "aws_iam_role" "ssm_role" {
#   name = "SSMRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm_attach" {
#   role       = aws_iam_role.ssm_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# # to attach an IAM role to an EC2 instance, we need to use an Instance Profile:
# resource "aws_iam_instance_profile" "ssm_profile" {
#   name = "SSMInstanceProfile"
#   role = aws_iam_role.ssm_role.name
# }

# resource "aws_security_group" "fastApi_ec2_sg" {
#   name        = "fastApi_ec2_sg"
#   description = "Allow all outbound traffic"
#   vpc_id      = aws_vpc.fastApi_vpc.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# data "aws_ami" "ami_filter" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023*-kernel-6.1-x86_64"]
#   }
# }
# resource "aws_instance" "fastApi_ec2" {
#   name = "${var.project_name}_ec2"
#   ami                         = data.aws_ami.ami_filter.id
#   instance_type               = "t2.micro"
#   associate_public_ip_address = false
#   subnet_id                   = aws_subnet.fastApi_sn_private_1.id
#   iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name

#   vpc_security_group_ids = [aws_security_group.fastApi_ec2_sg.id]

# }
