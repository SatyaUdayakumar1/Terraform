#Launch Template for web tier
resource "aws_launch_template" "web_launch_template" {
  name_prefix       = "weblaunchtemplate"
  image_id          = "ami-06ca3ca175f37dd66"
  instance_type     = "t2.micro"
  key_name          = "ARKey"
  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups             =[var.web_securitygroup_id] 
    subnet_id                   = var.public_subnet_az1_id
    delete_on_termination       = true
  }  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs{
        volume_size             = 8
        volume_type             = "gp2"
        delete_on_termination   =true
    }
  }   

    tags = {
      Name = "web ec2 launch template"
    }

}

#Launch Template for application tier
resource "aws_launch_template" "app_launch_template" {
  name_prefix       = "applaunchtemplate"
  image_id          = "ami-06ca3ca175f37dd66"
  instance_type     = "t2.micro"
  key_name          = "ARKey"
  network_interfaces {
    device_index                = 0
    associate_public_ip_address = false
    security_groups             = [var.app_securitygroup_id] 
    subnet_id                   = var.private_app_subnet_az1_id
    delete_on_termination       = true
  }  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs{
        volume_size             = 8
        volume_type             = "gp2"
        delete_on_termination   = true
    }
  }   
  
  

    tags = {
      Name = "app ec2 launch template"
    }
}




resource "aws_instance" "app_instance_az1" {
  ami             = aws_launch_template.app_launch_template.image_id
  instance_type   = aws_launch_template.app_launch_template.instance_type
  key_name        = aws_launch_template.app_launch_template.key_name
  security_groups = aws_launch_template.app_launch_template.security_group_names
  subnet_id       = var.private_app_subnet_az1_id

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = aws_launch_template.app_launch_template.latest_version
  }

    user_data = base64encode(<<-EOT
    #!/bin/bash
    # Fix ownership and permissions 
    sudo /bin/chown -R ec2-user:ec2-user /home/ec2-user
    sudo chmod 755 /home/ec2-user
    sudo chmod 644 /home/ec2-user/.bash_profile

    sudo yum update -y
    # Install corretto
    sudo amazon-linux-extras enable corretto8
    sudo yum install -y java-17-amazon-corretto-devel

    # Create a directory to install Corretto 17
    sudo mkdir -p /opt/corretto-17

    # Create a directory to install JarFile
    sudo mkdir -p /home/ec2-user/JarFile

    # Move Corretto 17 
    sudo mv /usr/lib/jvm/java-17-amazon-corretto /opt/corretto-17/

    
    # Set environment variables to use Corretto 17
    echo 'export JAVA_HOME=/opt/corretto-17/java-17-amazon-corretto' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc

    # Download student_info.jar from S3 bucket 
    wget -P /home/ec2-user/JarFile https://<s3bucket-name>.s3.amazonaws.com/<application.jar>
    java -jar /home/ec2-user/JarFile/<application.jar>
    
  EOT
  )

  tags    = {
    Name  = "app Instance1"
  }
}


resource "aws_instance" "app_instance_az2" {
  ami             = aws_launch_template.app_launch_template.image_id
  instance_type   = aws_launch_template.app_launch_template.instance_type
  key_name        = aws_launch_template.app_launch_template.key_name
  security_groups = aws_launch_template.app_launch_template.security_group_names
  subnet_id       = var.private_app_subnet_az2_id

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = aws_launch_template.app_launch_template.latest_version
  }

    user_data = base64encode(<<-EOT
    #!/bin/bash
    # Fix ownership and permissions 
    sudo /bin/chown -R ec2-user:ec2-user /home/ec2-user
    sudo chmod 755 /home/ec2-user
    sudo chmod 644 /home/ec2-user/.bash_profile

    sudo yum update -y
    # Install corretto
    sudo amazon-linux-extras enable corretto8
    sudo yum install -y java-17-amazon-corretto-devel

    # Create a directory to install Corretto 17
    sudo mkdir -p /opt/corretto-17

    # Create a directory to install JarFile
    sudo mkdir -p /home/ec2-user/JarFile

    # Move Corretto 17 
    sudo mv /usr/lib/jvm/java-17-amazon-corretto /opt/corretto-17/

    
    # Set environment variables to use Corretto 17
    echo 'export JAVA_HOME=/opt/corretto-17/java-17-amazon-corretto' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
    source ~/.bashrc

    # Download student_info.jar from S3 bucket 
    wget -P /home/ec2-user/JarFile https://<s3bucket-name>.s3.amazonaws.com/<application.jar>
    java -jar /home/ec2-user/JarFile/<application.jar>
    
  EOT
  )

  tags    = {
    Name  = "app Instance2"
  }
}


resource "aws_instance" "web_instance_az1" {
  ami             = aws_launch_template.web_launch_template.image_id
  instance_type   = aws_launch_template.web_launch_template.instance_type
  key_name        = aws_launch_template.web_launch_template.key_name
  security_groups = aws_launch_template.web_launch_template.security_group_names
  subnet_id       = var.public_subnet_az1_id

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = aws_launch_template.web_launch_template.latest_version
  }

    user_data = base64encode(<<-EOT
    #!/bin/bash
    # Install Apache web server or any other configurations you need
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo yum install -y aws-cli
    
    sed -i '49i\Listen 8080'  /etc/httpd/conf/httpd.conf
    sed -i '258i\LoadModule proxy_module modules/mod_proxy.so'  /etc/httpd/conf/httpd.conf
    sed -i '259i\LoadModule proxy_http_module modules/mod_proxy_http.so'  /etc/httpd/conf/httpd.conf

    echo "proxypass / http://${aws_instance.app_instance_az1.private_ip}:8080/" >> /etc/httpd/conf/httpd.conf
    echo "ProxyPassReverse / http://${aws_instance.app_instance_az1.private_ip}:8080/" >> /etc/httpd/conf/httpd.conf

    sudo systemctl restart httpd.service
  EOT
  )

  tags    = {
    Name  = "web Instance1"
  }
}

resource "aws_instance" "web_instance_az2" {
  ami             = aws_launch_template.web_launch_template.image_id
  instance_type   = aws_launch_template.web_launch_template.instance_type
  key_name        = aws_launch_template.web_launch_template.key_name
  security_groups = aws_launch_template.web_launch_template.security_group_names
  subnet_id       = var.public_subnet_az2_id

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = aws_launch_template.web_launch_template.latest_version
  }

    user_data = base64encode(<<-EOT
    #!/bin/bash
    # Install Apache web server or any other configurations you need
    sudo yum update -y
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo yum install -y aws-cli
    
    sed -i '49i\Listen 8080'  /etc/httpd/conf/httpd.conf
    sed -i '258i\LoadModule proxy_module modules/mod_proxy.so'  /etc/httpd/conf/httpd.conf
    sed -i '259i\LoadModule proxy_http_module modules/mod_proxy_http.so'  /etc/httpd/conf/httpd.conf

    # Fetch the private IP address of the app instance from AWS Systems Manager Parameter Store
    echo "proxypass / http://${aws_instance.app_instance_az2.private_ip}:8080/" >> /etc/httpd/conf/httpd.conf
    echo "ProxyPassReverse / http://${aws_instance.app_instance_az2.private_ip}:8080/" >> /etc/httpd/conf/httpd.conf

    sudo systemctl restart httpd.service
  EOT
  )

  tags    = {
    Name  = "web Instance2"
  }
}

