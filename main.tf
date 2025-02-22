data "aws_iam_policy_document" "assume_role" {
  count = length(keys(var.principals))

  statement {
    effect  = "Allow"
    actions = var.assume_role_actions

    principals {
      type        = element(keys(var.principals), count.index)
      identifiers = var.principals[element(keys(var.principals), count.index)]
    }
  }
}

data "aws_iam_policy_document" "assume_role_aggregated" {
  count                     = module.this.enabled ? 1 : 0
  override_policy_documents = data.aws_iam_policy_document.assume_role.*.json
}


resource "aws_iam_role" "default" {
  count                = module.this.enabled ? 1 : 0
  name                 = var.use_fullname ? module.this.id : module.this.name
  assume_role_policy   = join("", data.aws_iam_policy_document.assume_role_aggregated.*.json)
  description          = var.role_description
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permissions_boundary
  tags                 = module.this.tags
}

data "aws_iam_policy_document" "default" {
  count                     = module.this.enabled && var.policy_document_count > 0 ? 1 : 0
  override_policy_documents = var.policy_documents
}


resource "aws_iam_policy" "default" {
  count       = module.this.enabled && var.policy_document_count > 0 ? 1 : 0
  name        = module.this.id
  description = var.policy_description
  policy      = join("", data.aws_iam_policy_document.default.*.json)
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = module.this.enabled && var.policy_document_count > 0 ? 1 : 0
  role       = join("", aws_iam_role.default.*.name)
  policy_arn = join("", aws_iam_policy.default.*.arn)
}

resource "aws_iam_instance_profile" "default" {
  count = module.this.enabled && var.instance_profile_enabled ? 1 : 0
  name  = module.this.id
  role  = join("", aws_iam_role.default.*.name)
}
