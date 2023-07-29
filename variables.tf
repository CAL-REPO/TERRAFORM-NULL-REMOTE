variable "PROFILE" {
    type = string
    default = null
}

variable "LOCAL_HOST_PRI_KEY_FILE_NAME" {
    type = string
    default = ""
}

variable "REMOTE_HOST" {
    type = object({
        USER = string
        USER_DIR = string
        IP = string
        PRI_KEY_FILE = string
    })

    default = {
        USER = ""
        USER_DIR = ""
        IP = ""
        PRI_KEY_FILE = ""
    }
}

variable "REMOTE_EXECUTE_COMMAND" {
    type = list(string)
    default = []
}

variable "REMOTE_CREATE_FILEs" {
    type = list(object({
        CONTENT = string
        DESTINATION = string
        COMMAND = optional(list(string))
    }))

    default = []
}

variable "REMOTE_SEND_FILEs" {
    type = list(object({
        SOURCE = string
        DESTINATION = string
        COMMAND = optional(list(string))
    }))

    default = []
}