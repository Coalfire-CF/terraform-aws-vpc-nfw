resource "aws_iam_role" "flowlogs_role" {
  name = "${var.name}-flowlogs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
        },
    "Effect": "Allow",
    "Sid": ""
  }
]
}
EOF
}

resource "aws_iam_policy" "flowlogs_policy" {
  name        = "${var.name}-flowlogs-policy"
  description = "Policy to allow vpc flow logs to forward logs"

  policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "sts:AssumeRole"
    ],
    "Effect": "Allow",
    "Resource": "*"
  }
]
}
EOF
}

resource "aws_iam_role_policy_attachment" "flowlogs_policy" {
  role       = aws_iam_role.flowlogs_role.name
  policy_arn = aws_iam_policy.flowlogs_policy.arn
}
