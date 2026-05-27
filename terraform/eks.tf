module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 20.0"

    cluster_name = "devops-platform"
    cluster_version = "1.31"

    enable_cluster_creator_admin_permissions = true
    cluster_endpoint_public_access = true

    vpc_id = aws_vpc.main.id

    subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
    ]

    eks_managed_node_groups = {
        default = {
            instance_types = ["t3.medium"]
            min_size = 1 
            max_size = 2
            desired_size = 1
        }
  }
  tags ={
    Environment = "dev"
    Project = var.project_name
  }
}