# Application Load Balancer
resource "aws_lb" "chronicle_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public_subnets[*].id

  enable_deletion_protection = false

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "chronicle_tg" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.chronicle_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-tg"
  })
}

# ALB Listener
resource "aws_lb_listener" "chronicle_listener" {
  load_balancer_arn = aws_lb.chronicle_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.chronicle_tg.arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-listener"
  })
}

# Optional: HTTPS Listener (uncomment if you have SSL certificate)
# resource "aws_lb_listener" "chronicle_https_listener" {
#   load_balancer_arn = aws_lb.chronicle_alb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.ssl_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.chronicle_tg.arn
#   }
#
#   tags = merge(var.common_tags, {
#     Name = "${var.project_name}-https-listener"
#   })
# }