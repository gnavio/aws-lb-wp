# BALANCEADOR DE CARGA

resource "aws_lb" "LB" {
  name               = "LB"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.LB_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

# Agente de escucha HTTP
resource "aws_lb_listener" "listener_HTTP" {
  load_balancer_arn = aws_lb.LB.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.LB_tg.arn
  }
  depends_on        = [aws_lb_target_group.LB_tg]
}

# Agente de escucha HTTPS
# resource "aws_lb_listener" "listener_HTTPS" {
#   load_balancer_arn = aws_lb.LB.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = local.ssl_policy
#   certificate_arn   = local.certificate_arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.LB_tg.arn
#   }
#   depends_on        = [aws_lb_target_group.LB_tg]
# }

# Grupo de destino
resource "aws_lb_target_group" "LB_tg" {
  name        = "LB-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc.id

  depends_on  = [aws_lb.LB]
}

resource "aws_lb_target_group_attachment" "destino_tg" {
  target_group_arn = aws_lb_target_group.LB_tg.arn
  target_id        = aws_instance.wordpress.id
  port             = 80
}