# VPC
resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "eks-vpc"
    }
}

# Subnets
resource "aws_subnet" "public" {
    count             = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.${count.index + 1}.0/24"
    availability_zone = data.aws_availability_zones.available.names[count.index]

    map_public_ip_on_launch = true

    tags = {
        Name = "eks-public-subnet-${count.index + 1}"
    }
}

resource "aws_subnet" "private" {
    count             = 2
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.${count.index + 10}.0/24"
    availability_zone = data.aws_availability_zones.available.names[count.index]

    tags = {
        Name = "eks-private-subnet-${count.index + 1}"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "eks-igw"
    }
}

# NAT Gateway
resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name = "eks-eip"
    }
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public[0].id

    tags = {
        Name = "eks-nat"
    }

    depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block      = "0.0.0.0/0"
        gateway_id      = aws_internet_gateway.main.id
    }

    tags = {
        Name = "eks-public-rt"
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "eks-private-rt"
    }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
    count          = 2
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count          = 2
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "eks_cluster" {
    name   = "eks-cluster-sg"
    vpc_id = aws_vpc.main.id

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "eks-cluster-sg"
    }
}

resource "aws_security_group" "eks_nodes" {
    name   = "eks-nodes-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        security_groups = [aws_security_group.eks_cluster.id]
    }

    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = [aws_vpc.main.cidr_block]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "eks-nodes-sg"
    }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
    name = "eks-cluster-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster_role.name
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "eks_node_role" {
    name = "eks-node-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_registry_policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_node_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
    name            = "my-eks-cluster"
    role_arn        = aws_iam_role.eks_cluster_role.arn
    version         = "1.27"

    vpc_config {
        subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
        endpoint_private_access = true
        endpoint_public_access  = true
        security_group_ids      = [aws_security_group.eks_cluster.id]
    }

    depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

    tags = {
        Name = "my-eks-cluster"
    }
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
    cluster_name    = aws_eks_cluster.main.name
    node_group_name = "my-node-group"
    node_role_arn   = aws_iam_role.eks_node_role.arn
    subnet_ids      = aws_subnet.private[*].id

    scaling_config {
        desired_size = 2
        max_size     = 4
        min_size     = 1
    }

    instance_types = ["t3.medium"]

    depends_on = [
        aws_iam_role_policy_attachment.eks_worker_node_policy,
        aws_iam_role_policy_attachment.eks_cni_policy,
        aws_iam_role_policy_attachment.eks_registry_policy,
    ]

    tags = {
        Name = "my-node-group"
    }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
    state = "available"
}