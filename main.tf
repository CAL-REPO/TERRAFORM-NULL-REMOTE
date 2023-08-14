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

resource "null_resource" "REMOTE_PRE_EXECUTEs" {
    count = (length(var.REMOTE_PRE_EXECUTEs) > 0 ? length(var.REMOTE_PRE_EXECUTEs) : 0)
    depends_on = [ null_resource.BASE_RESOURCE_FOR_REMOTE_EXECUTION ]

    triggers = {
        always_run = try("${var.REMOTE_PRE_EXECUTEs[count.index].ALWAYS}" == true ? timestamp() : null, null)
        COMMANDs = base64encode(join(",", "${var.REMOTE_PRE_EXECUTEs[count.index].COMMANDs}"))
    }

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_PRE_EXECUTEs[count.index].COMMANDs}"
    }

}

resource "null_resource" "REMOTE_CREATE_FILEs" {
    count = (length(var.REMOTE_CREATE_FILEs) > 0 ? length(var.REMOTE_CREATE_FILEs) : 0)
    depends_on = [ null_resource.REMOTE_PRE_EXECUTEs ]

    triggers = {
        always_run = try("${var.REMOTE_CREATE_FILEs[count.index].ALWAYS}" == true ? timestamp() : null, null)
        CONTENT = "${var.REMOTE_CREATE_FILEs[count.index].CONTENT}"
        DESTINATION = "${var.REMOTE_CREATE_FILEs[count.index].DESTINATION}"
        COMMANDs = base64encode(join(",", "${var.REMOTE_CREATE_FILEs[count.index].COMMANDs}"))
    }

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = ["mkdir -p ${dirname(var.REMOTE_CREATE_FILEs[count.index].DESTINATION)}"]
    }

    provisioner "file" {
        destination = "${var.REMOTE_CREATE_FILEs[count.index].DESTINATION}"
        content = "${var.REMOTE_CREATE_FILEs[count.index].CONTENT}"
    }

    provisioner "remote-exec" {
        inline = ["while [ ! -f ${var.REMOTE_CREATE_FILEs[count.index].DESTINATION} ]; do sleep 5; done"]
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_CREATE_FILEs[count.index].COMMANDs}"
    }
}

# data "external" "REMOTE_SEND_FILE_DATA" {
#     count = (length(var.REMOTE_SEND_FILEs) > 0 ? length(var.REMOTE_SEND_FILEs) : 0)
#     depends_on = [ null_resource.REMOTE_PRE_EXECUTEs ]

#     program = ["bash", "-c", "cat ${var.REMOTE_SEND_FILEs[count.index].SOURCE}"]
# }


resource "null_resource" "REMOTE_SEND_FILEs" {
    count = (length(var.REMOTE_SEND_FILEs) > 0 ? length(var.REMOTE_SEND_FILEs) : 0)
    depends_on = [ null_resource.REMOTE_PRE_EXECUTEs ]

    triggers = {
        always_run  = try("${var.REMOTE_SEND_FILEs[count.index].ALWAYS}" == true ? timestamp() : null, null)
        SOURCE = "${var.REMOTE_SEND_FILEs[count.index].SOURCE}"
        DESTINATION = "${var.REMOTE_SEND_FILEs[count.index].DESTINATION}"
        COMMANDs = base64encode(join(",", "${var.REMOTE_SEND_FILEs[count.index].COMMANDs}"))
    }

    connection {
        host        = "${var.REMOTE_HOST.EXTERNAL_IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.LOCAL_HOST_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = [
            "mkdir -p ${dirname(var.REMOTE_SEND_FILEs[count.index].DESTINATION)}",
            "sudo rm -rf ${var.REMOTE_SEND_FILEs[count.index].DESTINATION}"
        ]
    }

    provisioner "file" {
        source = "${var.REMOTE_SEND_FILEs[count.index].SOURCE}"
        destination = "${var.REMOTE_SEND_FILEs[count.index].DESTINATION}"
    }

    provisioner "remote-exec" {
        inline = ["while [ ! -f ${var.REMOTE_SEND_FILEs[count.index].DESTINATION} ]; do sleep 5; done"]
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_SEND_FILEs[count.index].COMMANDs}"
    }
}

resource "null_resource" "REMOTE_EXECUTEs" {
    for_each = { for INDEX, REMOTE_EXECUTE in var.REMOTE_EXECUTEs : INDEX => REMOTE_EXECUTE }
    depends_on = [ null_resource.REMOTE_CREATE_FILEs, null_resource.REMOTE_SEND_FILEs ]

    triggers = {
        always_run = try("${each.value.ALWAYS}" == true ? timestamp() : null, null)
        LOCAL_PRI_KEY_FILE = "${each.value.LOCAL_PRI_KEY_FILE}"
        REMOTE_USER = "${each.value.REMOTE_USER}"
        REMOTE_IP = "${each.value.REMOTE_IP}"
        COMMANDs   = base64encode(join(",", "${each.value.COMMANDs}"))
    }

    connection {
        host        = "${self.triggers.REMOTE_IP}"
        type        = "ssh"
        user        = "${self.triggers.REMOTE_USER}"  # Update with your SSH username
        private_key = file("${self.triggers.LOCAL_PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = split(",", base64decode("${self.triggers.COMMANDs}"))
    }
}