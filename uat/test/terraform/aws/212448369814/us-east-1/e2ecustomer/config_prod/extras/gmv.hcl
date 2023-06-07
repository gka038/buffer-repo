locals {
    docker_image_tag                         = "0.0.1"
    forward_rule_schedule_expression         = "cron(0/10 08-13 ? * * *)"
    retro_rule_schedule_expression           = "cron(0/10 08-13 ? * * *)"
    create_retro_rule                        = false
    lambda_timeout                           = "300"
}
