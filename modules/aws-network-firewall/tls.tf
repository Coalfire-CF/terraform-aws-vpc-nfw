resource "aws_networkfirewall_tls_inspection_configuration" "example" {
  count = var.tls_inspection_enabled ? 1 : 0

  # General
  name        = "${var.prefix}-tls-inspection"
  description = var.tls_description

  # Encryption
  encryption_configuration {
    key_id = var.nfw_kms_key_id
    type   = "CUSTOMER_KMS"
  }


  # TLS Inspection
  tls_inspection_configuration {
    server_certificate_configuration {
      server_certificate {
        resource_arn = var.tls_cert_arn
      }
      scope {
        protocols = [6]
        destination_ports {
          from_port = var.tls_destination_from_port
          to_port   = var.tls_destination_to_port
        }
        destination {
          address_definition = var.tls_destination_cidr
        }
        source_ports {
          from_port = var.tls_source_from_port
          to_port   = var.tls_source_to_port
        }
        source {
          address_definition = var.tls_source_cidr
        }
      }
    }
  }
}