# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prd" ? true : false
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name        = "${var.project_name}-tg-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg-${var.environment}"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "main" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# ALB Listener (HTTP)
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Outputs
output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}
