# GitHub Actions → AWS without stored keys. Two roles:
#   plan   — read-only, assumable from pull requests (terraform plan)
#   deploy — assumable only from the "dev" GitHub environment, which is limited to main
# Fork PRs can't request an OIDC token, so outside contributors never reach either role.

data "aws_caller_identity" "current" {}

locals {
  github_repo  = "elephantebae/simmer"
  state_bucket = "arn:aws:s3:::${var.state_bucket}"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "trust_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repo}:pull_request"]
    }
  }
}

data "aws_iam_policy_document" "trust_deploy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repo}:environment:${var.environment}"]
    }
  }
}

# --- plan: read everything, write only the state lock file ---

resource "aws_iam_role" "gha_plan" {
  name                 = "simmer-gha-plan"
  assume_role_policy   = data.aws_iam_policy_document.trust_plan.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "gha_plan_readonly" {
  role       = aws_iam_role.gha_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "plan_state" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${local.state_bucket}/*"]
  }
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.state_bucket}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "gha_plan_state" {
  name   = "terraform-state-lock"
  role   = aws_iam_role.gha_plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}

# --- deploy: PowerUser, plus IAM only for simmer-* roles/policies ---

resource "aws_iam_role" "gha_deploy" {
  name                 = "simmer-gha-deploy"
  assume_role_policy   = data.aws_iam_policy_document.trust_deploy.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "gha_deploy_poweruser" {
  role       = aws_iam_role.gha_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "deploy_iam" {
  statement {
    sid = "ManageSimmerRoles"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:UpdateRole", "iam:UpdateAssumeRolePolicy",
      "iam:TagRole", "iam:UntagRole",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy",
      "iam:PassRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/simmer-*"]
  }
  statement {
    sid = "ManageSimmerPolicies"
    actions = [
      "iam:CreatePolicy", "iam:DeletePolicy", "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
      "iam:TagPolicy", "iam:UntagPolicy",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/simmer-*"]
  }
  statement {
    sid       = "ReadIam"
    actions   = ["iam:Get*", "iam:List*"]
    resources = ["*"]
  }
  # The deploy role can't widen its own access or the plan role's.
  statement {
    sid    = "ProtectCiRoles"
    effect = "Deny"
    actions = [
      "iam:UpdateAssumeRolePolicy", "iam:PutRolePolicy", "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:DeleteRole",
    ]
    resources = [
      aws_iam_role.gha_plan.arn,
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/simmer-gha-deploy",
    ]
  }
}

resource "aws_iam_role_policy" "gha_deploy_iam" {
  name   = "simmer-scoped-iam"
  role   = aws_iam_role.gha_deploy.id
  policy = data.aws_iam_policy_document.deploy_iam.json
}

output "gha_plan_role_arn" {
  value = aws_iam_role.gha_plan.arn
}

output "gha_deploy_role_arn" {
  value = aws_iam_role.gha_deploy.arn
}
