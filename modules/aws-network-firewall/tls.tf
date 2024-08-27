resource "aws_networkfirewall_tls_inspection_configuration" "tls_inspection" {
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
      certificate_authority_arn = var.tls_cert_arn
      check_certificate_revocation_status {
        revoked_status_action = "REJECT"
        unknown_status_action = "PASS"
      }
      dynamic "scope" {
        for_each = var.tls_destination_cidrs
        content {
          protocols = [6]
          destination_ports {
            from_port = var.tls_destination_from_port
            to_port   = var.tls_destination_to_port
          }
          destination {
            address_definition = scope.value
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

      #   scope {
      #     protocols = [6]
      #     destination_ports {
      #       from_port = var.tls_destination_from_port
      #       to_port   = var.tls_destination_to_port
      #     }
      #     destination {
      #       address_definition = var.tls_destination_cidr 
      #     }
      #     source_ports {
      #       from_port = var.tls_source_from_port
      #       to_port   = var.tls_source_to_port
      #     }
      #     source {
      #       address_definition = var.tls_source_cidr
      #     }
      #   }
    }
  }
}
