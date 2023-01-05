terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
#sns topic creation
resource "aws_sns_topic" "content_topic" {
  name         = "content_topic"
  display_name = "content_topic"

}
#sqs queue creation
resource "aws_sqs_queue" "content_q" {
  name                       = "content_q"
  visibility_timeout_seconds = 10
  max_message_size           = 65536 #64KB
  message_retention_seconds  = 900
}

#sqs queue policy for sns to send the message to this queue
resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.content_q.id

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Id": "__default_policy_ID",
    "Statement": [
        {
            "Sid": "__owner_statement",
            "Effect": "Allow",
            "Principal": {
                "AWS": "639095781608"
            },
            "Action": [
                "SQS:*"
            ],
            "Resource": "arn:aws:sqs:us-east-1:639095781608:content_q"
        },
        {
            "Sid": "Allow-SNS-SendMessage",
            "Effect": "Allow",
            "Principal": {
                "Service": "sns.amazonaws.com"
            },
            "Action": [
                "sqs:SendMessage"
            ],
            "Resource": "arn:aws:sqs:us-east-1:639095781608:content_q",
            "Condition": {
                "ArnEquals": {
                    "aws:SourceArn": "arn:aws:sns:us-east-1:639095781608:content_topic"
                }
            }
        }
    ]
}
POLICY
}

#content_topic topic subscription
resource "aws_sns_topic_subscription" "content_topic_subscription" {
  topic_arn = aws_sns_topic.content_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.content_q.arn
}