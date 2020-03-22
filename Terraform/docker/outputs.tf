output "url-docker" {
  #value = "http://${aws_instance.docker.0.public_ip}:8080"
  value = "${aws_instance.docker.0.public_ip}"
}