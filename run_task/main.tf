# This file provides a resource for running the ECS task
# Note: This will trigger the task every time you apply the Terraform configuration

resource "null_resource" "run_ecs_task" {
  provisioner "local-exec" {
    command = <<EOF
aws ecs run-task \
  --cluster "{{ $var.ecs_cluster_name }}" \
  --task-definition "{{ $var.task_definition }}" \
  --count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[{{ $var.subnet_id }}],securityGroups=[{{ $var.security_group_id }}],assignPublicIp=ENABLED}" \
  --region "{{ $var.region }}"
EOF
  }

  # This allows the task to be re-run when you run terraform apply again
  triggers = {
    always_run = "${timestamp()}"
  }
}
