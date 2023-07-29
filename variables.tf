variable "PROFILE" {
    type = string
    default = null
}


variable "REMOTE_HOST" {
    type = object({
        IP = string
        USER = string
        PRI_KEY_FILE = string
    })

    default = {
        IP = ""
        USER = ""
        PRI_KEY_FILE = ""
    }
}

variable "REMOTE_EXECUTE_COMMAND" {
    type = list(string)
    default = []
}

variable "REMOTE_CREATE_FILE" {
    type = list(object({
        CONTENT = string
        DESTINATION = string
    }))

    default = []
}