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

resource "null_resource" "BASE_RESOURCE_FOR_REMOTE_EXECUTION" {
    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        interpreter = ["bash", "-c"]
        command = <<-EOF
        if [ ! -f ${var.LOCAL_HOST_PRI_KEY_FILE} ]; then
            echo "\"LOCAL_HOST_PRI_KEY_FILE_PATH\" file is not exists."
            exit 1
        fi
        while true; do
            if ssh -q -o "StrictHostKeyChecking=no" -o "PreferredAuthentications=publickey" -i "${var.LOCAL_HOST_PRI_KEY_FILE}" "${var.REMOTE_HOST.USER}@${var.REMOTE_HOST.EXTERNAL_IP}" exit; then
                echo "SSH connection is now available. Remote PC has rebooted successfully."
                break
            else
                echo "SSH connection not available yet. Waiting for 10 seconds..."
                sleep 10
            fi
        done
        EOF
    }
}

resource "null_resource" "REMOTE_PRE_EXECUTE_COMMAND" {
    count = (length(var.REMOTE_PRE_EXECUTE_COMMAND) > 0 ? 1 : 0)
    depends_on = [ null_resource.BASE_RESOURCE_FOR_REMOTE_EXECUTION ]

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    triggers = {
        COMMAND = base64encode("${var.REMOTE_PRE_EXECUTE_COMMAND}")
    }

    # provisioner "remote-exec" {
    #     inline = "${var.REMOTE_PRE_EXECUTE_COMMAND}"
    # }

    provisioner "remote-exec" {
        inline = [base64decode("${self.triggers.COMMAND}")]
    }

}

resource "null_resource" "REMOTE_CREATE_FILE" {
    count = (length(var.REMOTE_CREATE_FILEs) > 0 ? length(var.REMOTE_CREATE_FILEs) : 0)
    depends_on = [ null_resource.REMOTE_PRE_EXECUTE_COMMAND ]

    triggers = {
        CONTENT = "${var.REMOTE_CREATE_FILEs[count.index].CONTENT}"
        DESTINATION = "${var.REMOTE_CREATE_FILEs[count.index].DESTINATION}"
        COMMAND = base64encode("${var.REMOTE_CREATE_FILEs[count.index].COMMAND}")
    }

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = ["if [ ! -d ${dirname(var.REMOTE_CREATE_FILEs[count.index].DESTINATION)} ]; then mkdir -p ${dirname(var.REMOTE_CREATE_FILEs[count.index].DESTINATION)}; fi"]
    }

    provisioner "file" {
        destination = "${var.REMOTE_CREATE_FILEs[count.index].DESTINATION}"
        content = "${var.REMOTE_CREATE_FILEs[count.index].CONTENT}"
    }

    provisioner "remote-exec" {
        inline = ["while [ ! -f ${var.REMOTE_CREATE_FILEs[count.index].DESTINATION} ]; do sleep 5; done"]
    }

    # provisioner "remote-exec" {
    #     inline = "${var.REMOTE_CREATE_FILEs[count.index].COMMAND}"
    # }

    provisioner "remote-exec" {
        inline = [base64decode("${self.triggers[count.index].COMMAND}")]
    }
}

resource "null_resource" "REMOTE_SEND_FILE" {
    count = (length(var.REMOTE_SEND_FILEs) > 0 ? length(var.REMOTE_SEND_FILEs) : 0)
    depends_on = [ null_resource.REMOTE_PRE_EXECUTE_COMMAND ]

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    triggers = {
        SOURCE = "${var.REMOTE_SEND_FILEs[count.index].SOURCE}"
        DESTINATION = "${var.REMOTE_SEND_FILEs[count.index].DESTINATION}"
        COMMAND = base64encode("${var.REMOTE_SEND_FILEs[count.index].COMMAND}")
    }

    provisioner "remote-exec" {
        inline = ["if [ ! -d ${dirname(var.REMOTE_SEND_FILEs[count.index].DESTINATION)} ]; then mkdir -p ${dirname(var.REMOTE_SEND_FILEs[count.index].DESTINATION)}; fi"]
    }

    provisioner "file" {
        source = "${var.REMOTE_SEND_FILEs[count.index].SOURCE}"
        destination = "${var.REMOTE_SEND_FILEs[count.index].DESTINATION}"
    }

    provisioner "remote-exec" {
        inline = ["while [ ! -f ${var.REMOTE_SEND_FILEs[count.index].DESTINATION} ]; do sleep 5; done"]
    }

    # provisioner "remote-exec" {
    #     inline = "${var.REMOTE_SEND_FILEs[count.index].COMMAND}"
    # }

    provisioner "remote-exec" {
        inline = [base64decode("${self.triggers[count.index].COMMAND}")]
    }

}

resource "null_resource" "REMOTE_EXECUTE_COMMAND" {
    count = (length(var.REMOTE_EXECUTE_COMMAND) > 0 ? 1 : 0)
    depends_on = [ null_resource.REMOTE_CREATE_FILE, null_resource.REMOTE_SEND_FILE ]

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    triggers = {
        COMMAND = base64encode("${var.REMOTE_EXECUTE_COMMAND}")
    }

    # provisioner "remote-exec" {
    #     inline = "${var.REMOTE_PRE_EXECUTE_COMMAND}"
    # }

    provisioner "remote-exec" {
        inline = [base64decode("${self.triggers.COMMAND}")]
    }
}