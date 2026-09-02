resource "aws_iam_openid_connect_provider" "githubOidc_ecr" {
 url = "https://token.actions.githubusercontent.com"

 client_id_list = [
   "sts.amazonaws.com"
 ]

 thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e"]
}

resource "aws_ecr_repository" "test-ecr-github-upload" {
  name                 = "github-upload"
  image_tag_mutability = "IMMUTABLE_WITH_EXCLUSION"

  image_scanning_configuration {
    scan_on_push = true
  }
  
  image_tag_mutability_exclusion_filter {
    filter      = "latest*"
    filter_type = "WILDCARD"
  }

  image_tag_mutability_exclusion_filter {
    filter      = "dev-*"
    filter_type = "WILDCARD"
  }
}


data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.githubOidc_ecr.arn]
    }

    # 1. Required Audience check
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # 2. Subject claim check (handling potential casing differences)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:JamesAAllsopp*/TestDockerImage-AWS-ECR*:*",
        #"repo:jamesaallsopp/TestDockerImage-AWS-ECR:*",
        #"repo:JamesAAllsopp/testdockerimage-aws-ecr:*",
        #"repo:jamesaallsopp/testdockerimage-aws-ecr:*"
      ]
    }
  }
}

resource "aws_iam_role" "github-role" {
  name               = "GithubActionsRole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

resource "aws_iam_role_policy" "github_ecr_policy" {
  name = "GithubActionsECRPermissions"
  role = aws_iam_role.github-role.id 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 1. Required for logging in (MUST be Resource "*")
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        # 2. Required for pushing docker images to your specific repository
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.test-ecr-github-upload.arn
      }
    ]
  })
}

