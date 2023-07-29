resource "null_resource" "REMOTE_EXECUTE_COMMAND" {
    count = (length(var.REMOTE_EXECUTE_COMMAND) > 0 ? 1 : 0)

    connection {
        host        = "${var.REMOTE_HOST.IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.REMOTE_HOST.PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    provisioner "remote-exec" {
        inline = "${var.REMOTE_EXECUTE_COMMAND}"
    }
}

resource "null_resource" "REMOTE_CREATE_FILE" {
    count = (length(var.REMOTE_CREATE_FILE) > 0 ? 1 : 0)

    connection {
        host        = "${var.REMOTE_HOST.IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.REMOTE_HOST.PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    dynamic "provisioner" {
        for_each = var.REMOTE_CREATE_FILE

        content {
            provisioner "file" {
                content     = provisioner.value.CONTENT
                destination = provisioner.value.DESTINATION
            }
        }
    }
    # provisioner "file" {
    #     content = "${var.REMOTE_CREATE_FILE.CONTENT}"
    #     destination = "${var.REMOTE_CREATE_FILE.DESTINATION}"
    # }
}

resource "null_resource" "REMOTE_SEND_FILE" {
    count = (length(var.RREMOTE_SEND_FILE_DATA.SOURCE) > 0 ? 1 : 0)

    connection {
        host        = "${var.REMOTE_HOST.IP}"
        type        = "ssh"
        user        = "${var.REMOTE_HOST.USER}"  # Update with your SSH username
        private_key = file("${var.REMOTE_HOST.PRI_KEY_FILE}")  # Update with the path to your private key file
    }

    dynamic "provisioner" {
        for_each = var.RREMOTE_SEND_FILE_DATA

        content {
            provisioner "file" {
                source      = provisioner.value.SOURCE
                destination = provisioner.value.DESTINATION
            }
        }
    }
}
