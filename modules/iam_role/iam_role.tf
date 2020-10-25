variable policy_document {
    # type = list(string)
    description = "policy document data"
}

variable identifiers {
    type        = list(string)
    description = "identifiers for assume policy"
}

variable name {
    type = string
    description = "policy and role name"
}

# IAMポリシーの作成
resource "aws_iam_policy" "default" {
    name = var.name
    path = "/"
    policy = var.policy_document
}

# ロールの信頼ポリシー（どのリソースにアタッチするのか）
data "aws_iam_policy_document" "default" {
    statement {
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = var.identifiers
        }
    }
}

# ロールの設定
resource "aws_iam_role" "default" {
    name = var.name
    assume_role_policy = data.aws_iam_policy_document.default.json
}

# ロールにポリシーをアタッチする
resource "aws_iam_role_policy_attachment" "ecs_role_attach" {
    role = aws_iam_role.default.name
    policy_arn = aws_iam_policy.default.arn
}

output role {
    value = aws_iam_role.default
}