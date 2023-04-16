#userdata for public subnet1
user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo echo "It was a success" > /var/www/html/index.html
    sudo systemctl start httpd
    sudo systemctl enable httpd
  EOF
}
