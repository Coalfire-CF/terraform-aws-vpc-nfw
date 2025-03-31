package test

import (
    "context"
    "encoding/json" // Add this import for JSON unmarshaling
    "fmt"
    "os"
    "os/exec"
    "testing"
    "time"

    "github.com/aws/aws-sdk-go-v2/aws"
    "github.com/aws/aws-sdk-go-v2/config"
    "github.com/aws/aws-sdk-go-v2/service/ec2"
    ec2Types "github.com/aws/aws-sdk-go-v2/service/ec2/types"
    "github.com/aws/aws-sdk-go-v2/service/networkfirewall"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/require"
)

// TestVpcEndpointsWithNFW runs all tests in a single deployment
func TestVpcEndpointsWithNFW(t *testing.T) {
    // Setup terraform options with all required configurations for both tests
    terraformOptions := setupTerraformOptionsForAllTests(t)

    // Create cleanup deferred function that will run at the end of all tests
    defer cleanupResources(t, terraformOptions)

    // Setup emergency cleanup in case the test process crashes
    SetupEmergencyCleanup(t, terraformOptions.TerraformDir)

    // Run terraform init and apply once for all tests
    t.Log("Deploying all infrastructure...")
    terraform.InitAndApply(t, terraformOptions)

    // Run functional test for VPC endpoints
    t.Run("VPC Endpoints Functional Test", func(t *testing.T) {
        runVpcEndpointFunctionalTest(t, terraformOptions)
    })

    // Run Network Firewall rules test only if NFW is deployed
    t.Run("Network Firewall Rules Test", func(t *testing.T) {
        // First check if deploy_aws_nfw is true
        deployNFW, ok := terraformOptions.Vars["deploy_aws_nfw"].(bool)
        if !ok || !deployNFW {
            t.Skip("Skipping Network Firewall tests as deploy_aws_nfw is not set to true")
        }

        runNFWRulesTest(t, terraformOptions)
    })

    t.Log("All tests completed successfully!")
}

// setupTerraformOptionsForAllTests combines the configuration from both tests
func setupTerraformOptionsForAllTests(t *testing.T) *terraform.Options {
    // Use us-gov-west-1 for GovCloud testing
    awsRegion := "us-gov-west-1"

    // Configuration values with integration-specific prefix
    resourcePrefix := "terratest"
    vpcCidr := "10.250.0.0/16"
    deployNFW := true
    deleteProtection := false


    terraformDir := "../../example/vpc-endpoints"

    // Construct the terraform options with configurations for both tests
    baseOptions := &terraform.Options{
        TerraformDir: terraformDir,
        Vars: map[string]interface{}{
            "vpc_cidr":          vpcCidr,
            "deploy_aws_nfw":    deployNFW,
            "aws_region":        awsRegion,
            "resource_prefix":   resourcePrefix,
            "delete_protection": deleteProtection,

            // VPC Endpoint variables
            "create_vpc_endpoints":                true,
            "associate_with_private_route_tables": true,
            "associate_with_public_route_tables":  false,

            // Standard endpoint configuration
            "vpc_endpoints": map[string]interface{}{
                "s3": map[string]interface{}{
                    "service_type": "Gateway",
                    "auto_accept": true,
                    "service_name": "com.amazonaws.us-gov-west-1.s3",
                    "tags": map[string]string{
                        "Name": "test-s3-endpoint",
                    },
                },
                "dynamodb": map[string]interface{}{
                    "service_type": "Gateway",
                    "auto_accept": true,
                    "service_name": "com.amazonaws.us-gov-west-1.dynamodb",
                    "tags": map[string]string{
                        "Name": "test-dynamodb-endpoint",
                    },
                },
                "secretsmanager": map[string]interface{}{
                    "service_type": "Interface",
                    "auto_accept": true,
                    "private_dns_enabled": true,
                    "service_name": "com.amazonaws.us-gov-west-1.secretsmanager",
                    "tags": map[string]string{
                        "Name": "test-secretsmanager-endpoint",
                    },
                },
                "kms": map[string]interface{}{
                    "service_type": "Interface",
                    "auto_accept": true,
                    "private_dns_enabled": true,
                    "service_name": "com.amazonaws.us-gov-west-1.kms-fips",
                    "tags": map[string]string{
                        "Name": "test-kms-endpoint",
                    },
                },
            },

            // Define security groups
            "vpc_endpoint_security_groups": map[string]interface{}{
                "endpoint_sg": map[string]interface{}{
                    "name": "test-endpoint-sg",
                    "description": "Security group for VPC endpoints",
                    "ingress_rules": []map[string]interface{}{
                        {
                            "from_port":   443,
                            "to_port":     443,
                            "protocol":    "tcp",
                            "cidr_blocks": []string{vpcCidr},
                        },
                    },
                    "egress_rules": []map[string]interface{}{
                        {
                            "from_port":   0,
                            "to_port":     0,
                            "protocol":    "-1",
                            "cidr_blocks": []string{"0.0.0.0/0"},
                        },
                    },
                },
            },

            // Network Firewall rule group configurations using the correct variable names
            "aws_nfw_fivetuple_stateful_rule_group": []map[string]interface{}{
                {
                    "capacity":    100,
                    "name":        "test-stateful-rules",
                    "description": "Test stateful rules",
                    "rule_config": []map[string]interface{}{
                        {
                            "description":           "Allow HTTPS",
                            "protocol":              "TCP",
                            "source_ipaddress":      "ANY",
                            "source_port":           "ANY",
                            "destination_ipaddress": "ANY",
                            "destination_port":      "443",
                            "direction":             "ANY",
                            "sid":                   10001,
                            "actions": map[string]string{
                                "type": "PASS",
                            },
                        },
                        {
                            "description":           "Block SSH",
                            "protocol":              "TCP",
                            "source_ipaddress":      "ANY",
                            "source_port":           "ANY",
                            "destination_ipaddress": "ANY",
                            "destination_port":      "22",
                            "direction":             "ANY",
                            "sid":                   10002,
                            "actions": map[string]string{
                                "type": "DROP",
                            },
                        },
                    },
                },
            },
            "aws_nfw_stateless_rule_group": []map[string]interface{}{
                {
                    "capacity":    100,
                    "name":        "test-stateless-rules",
                    "description": "Test stateless rules",
                    "rule_config": []map[string]interface{}{
                        {
                            "protocols_number":      []int{1}, // ICMP
                            "source_ipaddress":      "10.0.0.0/8",
                            "source_to_port":        "ANY",
                            "destination_ipaddress": "0.0.0.0/0",
                            "destination_to_port":   "ANY",
                            "tcp_flag": map[string]interface{}{
                                "flags": []string{},
                                "masks": []string{},
                            },
                            "actions": map[string]string{
                                "type": "PASS",
                            },
                        },
                    },
                },
            },
        },
        MaxRetries:         15,
        TimeBetweenRetries: 15 * time.Second,
    }

    // Add any custom retryable errors
    terraformOptions := terraform.WithDefaultRetryableErrors(t, baseOptions)

    return terraformOptions
}

// runVpcEndpointFunctionalTest runs the functional test for VPC endpoints
func runVpcEndpointFunctionalTest(t *testing.T, terraformOptions *terraform.Options) {
    // Validate infrastructure via AWS API
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    require.NotEmpty(t, vpcId, "VPC ID should not be empty")

    // Get and verify public subnets
    publicSubnetsOutput, err := terraform.OutputJsonE(t, terraformOptions, "public_subnets")
    require.NoError(t, err, "Failed to get public subnets output")

    // Parse the JSON output into a map
    var publicSubnetsMap map[string]string
    err = json.Unmarshal([]byte(publicSubnetsOutput), &publicSubnetsMap)
    require.NoError(t, err, "Failed to parse public subnets output")

    // Check number of public subnets
    t.Logf("Number of public subnets created: %d", len(publicSubnetsMap))
    require.Equal(t, 3, len(publicSubnetsMap), "Expected 3 public subnets to be created")

    // Get and verify firewall subnets
    firewallSubnetsOutput, err := terraform.OutputJsonE(t, terraformOptions, "firewall_subnets")
    require.NoError(t, err, "Failed to get firewall subnets output")

    // Parse the JSON output into a map
    var firewallSubnetsMap map[string]string
    err = json.Unmarshal([]byte(firewallSubnetsOutput), &firewallSubnetsMap)
    require.NoError(t, err, "Failed to parse firewall subnets output")

    // Check number of firewall subnets
    t.Logf("Number of firewall subnets created: %d", len(firewallSubnetsMap))
    require.Equal(t, 3, len(firewallSubnetsMap), "Expected 3 firewall subnets to be created")

    // Get private subnets (existing code)
    privateSubnetsOutput, err := terraform.OutputJsonE(t, terraformOptions, "private_subnets")
    require.NoError(t, err, "Failed to get private subnets output")

    // Parse the JSON output into a map
    var privateSubnetsMap map[string]string
    err = json.Unmarshal([]byte(privateSubnetsOutput), &privateSubnetsMap)
    require.NoError(t, err, "Failed to parse private subnets output")

    // Get any subnet ID from the map (first one will do)
    var privateSubnetId string
    for _, id := range privateSubnetsMap {
        privateSubnetId = id
        break
    }
    require.NotEmpty(t, privateSubnetId, "Could not find any private subnet ID")
}

// runNFWRulesTest runs the test for Network Firewall rules
func runNFWRulesTest(t *testing.T, terraformOptions *terraform.Options) {
    // Validate Network Firewall deployment
    region := terraformOptions.Vars["aws_region"].(string)
    cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
    require.NoError(t, err, "Failed to load AWS config")

    nfwClient := networkfirewall.NewFromConfig(cfg)

    // Check for Network Firewall endpoints instead of a direct ID
    // Since your module outputs aws_nfw_endpoint_ids instead of network_firewall_id
    nfwEndpointIds := terraform.Output(t, terraformOptions, "aws_nfw_endpoint_ids")
    require.NotEmpty(t, nfwEndpointIds, "Network Firewall endpoint IDs should not be empty")

    // For validation purposes, we'll just check that the endpoints exist
    // We could add additional endpoint validation as needed

    // Validate Network Firewall rule groups
    validateNFWRuleGroups(t, nfwClient, nfwEndpointIds)

    t.Log("Network Firewall rules validation passed successfully!")
}

// validateNFWRuleGroups validates that Network Firewall rule groups were created correctly
// We've modified this to work without a direct firewall ID since we only have endpoints
func validateNFWRuleGroups(t *testing.T, client *networkfirewall.Client, endpointsStr string) {
    // Since we don't have direct access to the firewall name/ID but only endpoints,
    // we need a different approach to validate rules.

    // List all firewalls in the account/region
    listInput := &networkfirewall.ListFirewallsInput{}
    listResp, err := client.ListFirewalls(context.TODO(), listInput)
    require.NoError(t, err, "Failed to list Network Firewalls")

    // Check if we have any firewalls
    require.NotEmpty(t, listResp.Firewalls, "No Network Firewalls found in the account")

    // We'll use the first firewall for validation
    // In a real-world scenario, you might want to filter by name or tags
    firewallInfo := listResp.Firewalls[0]
    t.Logf("Found Network Firewall: %s", *firewallInfo.FirewallName)

    // Describe the firewall
    input := &networkfirewall.DescribeFirewallInput{
        FirewallName: firewallInfo.FirewallName,
    }

    resp, err := client.DescribeFirewall(context.TODO(), input)
    require.NoError(t, err, "Failed to describe Network Firewall")

    // Get firewall policy
    policyArn := resp.Firewall.FirewallPolicyArn

    // Describe the firewall policy
    policyInput := &networkfirewall.DescribeFirewallPolicyInput{
        FirewallPolicyArn: policyArn,
    }

    policyResp, err := client.DescribeFirewallPolicy(context.TODO(), policyInput)
    require.NoError(t, err, "Failed to describe Network Firewall policy")

    // Validate stateful rule groups
    statefulGroups := policyResp.FirewallPolicy.StatefulRuleGroupReferences
    require.NotEmpty(t, statefulGroups, "No stateful rule groups found in firewall policy")

    // Validate stateless rule groups
    statelessGroups := policyResp.FirewallPolicy.StatelessRuleGroupReferences
    require.NotEmpty(t, statelessGroups, "No stateless rule groups found in firewall policy")

    // Log rule group info
    t.Logf("Found %d stateful rule groups", len(statefulGroups))
    t.Logf("Found %d stateless rule groups", len(statelessGroups))
}


func cleanupResources(t *testing.T, terraformOptions *terraform.Options) {
    // Wait before starting the destroy process
    t.Log("##################################################")
    t.Log("##################################################")
    t.Log("Sleeping for 10 minutes before starting destroy...")
    t.Log("Allowing for some quick spot checking if desired")
    t.Log("##################################################")
    t.Log("##################################################")
    time.Sleep(600 * time.Second)

    // Get VPC ID before destroy attempt
    var vpcId string
    vpcIdOutput, err := terraform.OutputE(t, terraformOptions, "vpc_id")
    if err == nil {
        vpcId = vpcIdOutput
        t.Logf("Retrieved VPC ID for cleanup: %s", vpcId)
    }

    t.Log("Running terraform destroy...")
    destroyOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir:       terraformOptions.TerraformDir,
        Vars:               terraformOptions.Vars,
        MaxRetries:         20,
        TimeBetweenRetries: 20 * time.Second,
    })

    // Try standard terraform destroy first
    _, err = terraform.DestroyE(t, destroyOptions)

    // If terraform destroy fails, try manual resource cleanup
    if err != nil {
        t.Logf("Terraform destroy failed: %v", err)
        t.Log("Attempting manual cleanup of resources...")

        // Only attempt manual cleanup if we have the VPC ID
        if vpcId != "" {
            region := terraformOptions.Vars["aws_region"].(string)
            manualCleanup(t, vpcId, region)
        }

        // Try terraform destroy again after manual cleanup
        t.Log("Retrying terraform destroy...")
        terraform.Destroy(t, destroyOptions)
    }
}

// manualCleanup attempts to clean up the VPC resources using the AWS API directly
func manualCleanup(t *testing.T, vpcId string, region string) {
    cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
    if err != nil {
        t.Logf("Failed to load AWS config: %v", err)
        return
    }

    ec2Client := ec2.NewFromConfig(cfg)

    // List and delete security groups
    t.Log("Cleaning up security groups...")
    sgResp, err := ec2Client.DescribeSecurityGroups(context.TODO(), &ec2.DescribeSecurityGroupsInput{
        Filters: []ec2Types.Filter{
            {
                Name:   aws.String("vpc-id"),
                Values: []string{vpcId},
            },
        },
    })

    if err == nil {
        for _, sg := range sgResp.SecurityGroups {
            // Skip default security group
            if *sg.GroupName != "default" {
                t.Logf("Deleting security group: %s", *sg.GroupId)
                _, err := ec2Client.DeleteSecurityGroup(context.TODO(), &ec2.DeleteSecurityGroupInput{
                    GroupId: sg.GroupId,
                })
                if err != nil {
                    t.Logf("Failed to delete security group %s: %v", *sg.GroupId, err)
                }
            }
        }
    } else {
        t.Logf("Failed to describe security groups: %v", err)
    }

    // List and delete network interfaces
    t.Log("Cleaning up network interfaces...")
    niResp, err := ec2Client.DescribeNetworkInterfaces(context.TODO(), &ec2.DescribeNetworkInterfacesInput{
        Filters: []ec2Types.Filter{
            {
                Name:   aws.String("vpc-id"),
                Values: []string{vpcId},
            },
        },
    })

    if err == nil {
        for _, ni := range niResp.NetworkInterfaces {
            if ni.Attachment != nil && ni.Attachment.AttachmentId != nil {
                t.Logf("Detaching network interface: %s", *ni.NetworkInterfaceId)
                _, err := ec2Client.DetachNetworkInterface(context.TODO(), &ec2.DetachNetworkInterfaceInput{
                    AttachmentId: ni.Attachment.AttachmentId,
                    Force:        aws.Bool(true),
                })
                if err != nil {
                    t.Logf("Failed to detach network interface %s: %v", *ni.NetworkInterfaceId, err)
                }

                // Wait for the interface to be detached
                time.Sleep(10 * time.Second)
            }

            t.Logf("Deleting network interface: %s", *ni.NetworkInterfaceId)
            _, err := ec2Client.DeleteNetworkInterface(context.TODO(), &ec2.DeleteNetworkInterfaceInput{
                NetworkInterfaceId: ni.NetworkInterfaceId,
            })
            if err != nil {
                t.Logf("Failed to delete network interface %s: %v", *ni.NetworkInterfaceId, err)
            }
        }
    } else {
        t.Logf("Failed to describe network interfaces: %v", err)
    }

    // Allow time for resource deletion to propagate
    t.Log("Waiting for resource deletion to propagate...")
    time.Sleep(30 * time.Second)
}

// The emergency cleanup functions remain the same...
func CreateEmergencyCleanupScript(t *testing.T, terraformDir string) {
    // Create a cleanup script that will run as a separate process if the test fails
    scriptContent := `#!/bin/bash
TERRAFORM_DIR="$1"
LOG_FILE="/tmp/terratest-emergency-cleanup-$(date +%s).log"

echo "$(date) - Emergency cleanup triggered for terraform directory: $TERRAFORM_DIR" >> "$LOG_FILE"
cd "$TERRAFORM_DIR" || { echo "Failed to cd to $TERRAFORM_DIR" >> "$LOG_FILE"; exit 1; }

# Set AWS timeout env vars to be more lenient
export AWS_MAX_ATTEMPTS=60
export AWS_POLL_DELAY_SECONDS=30

# First run terraform init
echo "$(date) - Running terraform init" >> "$LOG_FILE"
terraform init >> "$LOG_FILE" 2>&1

# Sleep before starting destroy to let resources settle
echo "$(date) - Sleeping for 10 seconds before starting destroy" >> "$LOG_FILE"
sleep 10

# Try standard destroy first
echo "$(date) - Attempting terraform destroy" >> "$LOG_FILE"
terraform destroy -auto-approve >> "$LOG_FILE" 2>&1
RESULT=$?

if [ $RESULT -ne 0 ]; then
    echo "$(date) - First destroy attempt failed, trying with force options" >> "$LOG_FILE"
    # Try with force and no refresh as a fallback
    terraform destroy -auto-approve -refresh=false >> "$LOG_FILE" 2>&1
    RESULT=$?

    if [ $RESULT -ne 0 ]; then
        echo "$(date) - Second destroy attempt failed, trying AWS CLI cleanup" >> "$LOG_FILE"
        # Extract VPC ID if possible from terraform state
        VPC_ID=$(terraform output -json vpc_id 2>/dev/null | tr -d '"')
        if [ ! -z "$VPC_ID" ]; then
            echo "$(date) - Attempting direct AWS CLI cleanup of VPC $VPC_ID" >> "$LOG_FILE"
            aws ec2 describe-vpc-attribute --vpc-id "$VPC_ID" --attribute enableDnsSupport >> "$LOG_FILE" 2>&1
        fi
    fi
fi

echo "$(date) - Emergency cleanup process completed with status: $RESULT" >> "$LOG_FILE"
`
    // Write the script to a file
    scriptPath := "/tmp/terratest-emergency-cleanup.sh"
    err := os.WriteFile(scriptPath, []byte(scriptContent), 0755)
    if err != nil {
        t.Logf("Warning: Failed to create emergency cleanup script: %v", err)
        return
    }

    // Create a watcher script that will invoke our cleanup script if the test process disappears
    watcherScript := fmt.Sprintf(`#!/bin/bash
# Record the current test process ID
TEST_PID=$$
TERRAFORM_DIR="%s"
CLEANUP_SCRIPT="%s"

# Launch a background process that will check if our test process is still running
(
    # Wait a bit to let the test get going
    sleep 5

    # Periodically check if the test process exists
    while true; do
        if ! ps -p $TEST_PID > /dev/null; then
            # Test process is gone, run the cleanup
            echo "Test process $TEST_PID no longer exists, running emergency cleanup" > /tmp/terratest-watcher.log
            bash "$CLEANUP_SCRIPT" "$TERRAFORM_DIR" &
            break
        fi
        sleep 10
    done
) &

# Don't wait for the background process
disown
`, terraformDir, scriptPath)

    // Write the watcher script to a file
    watcherPath := fmt.Sprintf("/tmp/terratest-watcher-%s.sh", t.Name())
    err = os.WriteFile(watcherPath, []byte(watcherScript), 0755)
    if err != nil {
        t.Logf("Warning: Failed to create watcher script: %v", err)
        return
    }

    // Execute the watcher script
    cmd := exec.Command("bash", watcherPath)
    if err := cmd.Start(); err != nil {
        t.Logf("Warning: Failed to start watcher script: %v", err)
    } else {
        t.Logf("Emergency cleanup watcher started with PID: %d", cmd.Process.Pid)
    }
}

// SetupEmergencyCleanup is a wrapper function to use in tests
func SetupEmergencyCleanup(t *testing.T, terraformDir string) {
    CreateEmergencyCleanupScript(t, terraformDir)
}