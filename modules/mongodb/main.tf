# Unit testing modules
# module "vpc" {
#   source = "../vpc"

#   vpc_name = "${var.vpc_name}" # Let's make sure this gets added as a tag
#   vpc_cidr = "${var.vpc_cidr}"

#   vpc_enable_dns_hostnames    = "${var.vpc_enable_dns_hostnames}"
#   vpc_enable_dns_support      = "${var.vpc_enable_dns_support}"
#   vpc_create_internet_gateway = "${var.vpc_create_internet_gateway}"

#   vpc_tags = {
#     Owner       = "${var.candidate_name}"
#     Environment = "${var.environment}"
#   }
# }


# module "subnets" {
#     source = "../../modules/subnets"

#     subnets_target_vpc_id      = "${module.vpc.vpc_id}"
#     subnets_target_vpc_igw_id  = "${module.vpc.vpc_igw_id}"
#     public_route_table_id = "${module.vpc.public_rt_id}"
#     default_rotue_table_id = "${module.vpc.default_private_rt_id}"
#     cidrs = "${var.cidrs}"
#     subnets_az_state_filter    = "${var.subnets_az_state_filter}"
#     subnets_private_count      = "${var.subnets_private_count}"  # Let's make sure to use distinct AZs for each
#     subnets_public_count       = "${var.subnets_public_count}"
#     subnets_enable_nat_gateway = "${var.subnets_enable_nat_gateway}"

#     subnets_tags = {
#         Owner       = "${var.candidate_name}"
#         Environment = "${var.environment}"
#     }
# }

#Security groups

resource "aws_security_group" "mongodb_sg" {
  name        = "mongodb_sg"
  description = "Used for access to the mongodb instances"
  vpc_id      = "${var.mongo_vpc_id}"

  tags = "${merge(var.mongo_tags, map("Name", format("%s_mongodb_sg", var.vpc_name)))}"

  #mongodb related conf
  ingress {
    from_port   = 27019
    to_port     = 27019
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port   = 27017
    to_port     = 27017
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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# #key pair
resource "aws_key_pair" "app_auth" {
   key_name   = "mongodb_key"
   public_key = "${var.mongo_provisioning_key}"
}



resource "aws_instance" "mongodb_instances" {
  instance_type = "${var.mongo_instance_type}"
  ami           = "${var.mongo_ami}"

   tags = "${merge(var.mongo_tags, map("Name", format("%s_mongodb_server", var.vpc_name)))}"

  root_block_device {
        volume_type = "${var.mongo_volume_type}"
        volume_size = "${var.mongo_volume_size}"
  }

  key_name               = "${aws_key_pair.app_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.mongodb_sg.id}"]
  subnet_id              = "${var.mongo_subnet[0]}"
  user_data = "${file("${path.module}/files/user_data.sh")}"
}

# Volume to be attached
# resource "aws_ebs_volume" "mongodb_volume" {
#   availability_zone = "us-east-1a"
#   size              = "${var.mongo_volume_size}"
#   type = "${var.mongo_volume_type}"

#   tags = {
#     Name = "mongodb_volume"
#   }
# }

# resource "aws_volume_attachment" "ebs_att" {
#   device_name = "/dev/sdh"
#   volume_id   = "${aws_ebs_volume.mongodb_volume.id}"
#   instance_id = "${aws_instance.mongodb_instances.id}"
# }