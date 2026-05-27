resource "aws_ecr_repository" "sample_app" {
  name = var.repository_name
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = {
    Project = "cloud-native-platform"
    Environment = "dev"
  }
}