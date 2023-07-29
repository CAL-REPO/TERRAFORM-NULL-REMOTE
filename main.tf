# Standard AWS Provider Block
terraform {
    required_version = ">= 1.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = ">= 5.0"
        }
    }
}

resource "null_resource" "TEST" {
    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        on_failure = continue # Add this line to ignore errors
        command = <<-EOF
        echo "TEST"
        EOF
    }
}

resource "null_resource" "REMOTE_EXECUTE_COMMAND" {
    count = (length(var.REMOTE_EXECUTE_COMMAND) > 0 ? 1 : 0)

    connection {
        host        = "${var.REMOTE_HOST.IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_EXECUTE_COMMAND}"
    }
}

resource "null_resource" "REMOTE_CREATE_FILE" {
    count = (length(var.REMOTE_CREATE_FILEs) > 0 ? length(var.REMOTE_CREATE_FILEs) : 0)

    connection {
        host        = "${var.REMOTE_HOST.IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "file" {
        destination = "${var.REMOTE_CREATE_FILEs[count.index].DESTINATION}"
        content = "${var.REMOTE_CREATE_FILEs[count.index].CONTENT}"
    }

    provisioner "remote-exec" {
        inline = ["${var.REMOTE_CREATE_FILEs[count.index].DESTINATION} ; do sleep 5; done"]
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_CREATE_FILEs[count.index].COMMAND}"
    }
}

resource "null_resource" "REMOTE_SEND_FILE" {
    count = (length(var.REMOTE_SEND_FILEs) > 0 ? length(var.REMOTE_SEND_FILEs) : 0)

    connection {
        host        = "${var.REMOTE_HOST.IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "file" {
        source = "${var.REMOTE_SEND_FILEs[count.index].SOURCE}"
        destination = "${var.REMOTE_SEND_FILEs[count.index].DESTINATION}"
    }

    provisioner "remote-exec" {
        inline = ["${var.REMOTE_SEND_FILEs[count.index].DESTINATION} ; do sleep 5; done"]
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_SEND_FILEs[count.index].COMMAND}"
    }
}
