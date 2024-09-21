output "pub-ip" {
  value = aws_instance.jenkins-controller.public_ip
}