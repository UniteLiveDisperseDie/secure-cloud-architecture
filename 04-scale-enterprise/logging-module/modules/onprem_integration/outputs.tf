output "firehose_streams" {
  sensitive = true
  value = {
    for k, v in aws_kinesis_firehose_delivery_stream.this : k => {
      stream_name            = v.name
      credentials_secret_arn = aws_secretsmanager_secret.fluentbit[k].arn
    }
  }
}
