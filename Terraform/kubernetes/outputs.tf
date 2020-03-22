output "Master" {
  
  value = "${aws_instance.master[0].public_ip}"
  
}

output "Worker1" {
  
  value = "${aws_instance.worker[0].public_ip}"
  
}


output "Worker2" {
  
  value = "${aws_instance.worker[1].public_ip}"
  
}