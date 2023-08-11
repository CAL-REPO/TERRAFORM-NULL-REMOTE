variable "PROFILE" {
    type = string
    default = null
}

variable "LOCAL_HOST_PRI_KEY_FILE" {
    type = string
    default = ""
}

variable "REMOTE_HOST" {
    type = object({
        USER = string
        USER_DIR = string
        EXTERNAL_IP = string
    })

    default = {
        USER = ""
        USER_DIR = ""
        EXTERNAL_IP = ""
    }
}

variable "REMOTE_PRE_EXECUTEs" {
    type = list(object({
        ALWAYS = optional(bool)
        COMMAND = list(string)
    }))
    default = []
}

variable "REMOTE_CREATE_FILEs" {
    type = list(object({
        ALWAYS = optional(bool)
        CONTENT = string
        DESTINATION = string
        COMMAND = optional(list(string))
    }))

    default = []
}

variable "REMOTE_SEND_FILEs" {
    type = list(object({
        ALWAYS = optional(bool)
        SOURCE = string
        DESTINATION = string
        COMMAND = optional(list(string))
    }))

    default = []
}

variable "REMOTE_EXECUTEs" {
    type = list(object({
        ALWAYS = optional(bool)
        COMMAND = list(string)
    }))
    default = []
}