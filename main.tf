variable "region" {
  description = "Id of region"
  type        = string
  default = "cn-beijing"
}
variable "zone_for_ecs" {
  description = "Available zone id for creating Ecs Instances."
  type        = string
  default = "cn-beijing-e"
}
variable "zone_for_rds" {
  description = "Available zone id for creating Rds Instance."
  type        = string
  default = "cn-beijing-d"
}

variable "env" {
  description = "Name of security group. It is used to create a new security group. A random name prefixed with 'terraform-sg-' will be set if it is empty."
  type        = string
  default     = "test"
}

variable "security_name" {
  description = "Name of security group. It is used to create a new security group. A random name prefixed with 'terraform-sg-' will be set if it is empty."
  type        = string
  default     = "for-demo"
}

provider "alicloud" {
  region = var.region
}

resource "alicloud_vpc" "this" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Env = var.env
  }
}

resource "alicloud_vswitch" "for-ecs" {
  availability_zone = var.zone_for_ecs
  cidr_block        = "172.16.1.0/24"
  vpc_id            = alicloud_vpc.this.id
  tags = {
    Env = var.env
  }
}

resource "alicloud_vswitch" "for-rds" {
  availability_zone = var.zone_for_rds
  cidr_block        = "172.16.2.0/24"
  vpc_id            = alicloud_vpc.this.id
  tags = {
    Env = var.env
  }
}

resource "alicloud_nat_gateway" "this" {
  vpc_id = alicloud_vpc.this.id
}

resource "alicloud_security_group" "this" {
  count  = 4
  name   = format("%s%.03d", var.security_name, count.index)
  vpc_id = alicloud_vpc.this.id
  tags = {
    Env = var.env
  }
}

resource "alicloud_instance" "this" {
  count           = 4
  image_id        = "ubuntu_18_04_x64_20G_alibase_20200717.vhd"
  instance_type   = "ecs.sn1ne.large"
  security_groups = [element(alicloud_security_group.this.*.id, count.index)]
  instance_name   = element(alicloud_security_group.this.*.name, count.index)
  vswitch_id      = alicloud_vswitch.for-ecs.id
  tags = {
    Env = var.env
  }
}

resource "alicloud_eip" "this" {
  count = 3
  bandwidth = 10
  tags = {
    Env = var.env
  }
}

resource "alicloud_common_bandwidth_package" "this" {
  bandwidth = 10
}

resource "alicloud_common_bandwidth_package_attachment" "this" {
  count                = 3
  bandwidth_package_id = alicloud_common_bandwidth_package.this.id
  instance_id          = element(alicloud_eip.this.*.id, count.index)
}

resource "alicloud_eip_association" "fog-ecs" {
  count         = 2
  allocation_id = element(alicloud_eip.this.*.id, count.index)
  instance_id   = element(alicloud_instance.this.*.id, count.index)
}

resource "alicloud_eip_association" "for-nat" {
  allocation_id = element(alicloud_eip.this.*.id, 2)
  instance_id   = alicloud_nat_gateway.this.id
}

resource "alicloud_snat_entry" "this" {
  snat_ip           = element(alicloud_eip.this.*.ip_address, 2)
  snat_table_id     = alicloud_nat_gateway.this.snat_table_ids
  source_vswitch_id = alicloud_vswitch.for-ecs.id
  depends_on        = [alicloud_eip_association.for-nat]
}

resource "alicloud_db_instance" "this" {
  engine           = "MySQL"
  engine_version   = "5.6"
  instance_storage = 50
  instance_type    = "rds.mysql.s2.large"
  vswitch_id       = alicloud_vswitch.for-rds.id
  tags = {
    Env = var.env
  }
}