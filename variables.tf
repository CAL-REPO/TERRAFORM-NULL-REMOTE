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
        COMMANDs = list(string)
    }))
    
    default = []
}

variable "REMOTE_CREATE_FILEs" {
    type = list(object({
        ALWAYS = optional(bool)
        CONTENT = string
        DESTINATION = string
        COMMANDs = optional(list(string))
    }))

    default = []
}

variable "REMOTE_SEND_FILEs" {
    type = list(object({
        ALWAYS = optional(bool)
        SOURCE = string
        DESTINATION = string
        COMMANDs = optional(list(string))
    }))

    default = []
}

variable "REMOTE_EXECUTEs" {
    type = list(object({
        LOCAL_PRI_KEY_FILE = string
        REMOTE_USER = string
        REMOTE_IP = string
        ALWAYS = optional(bool)
        COMMANDs = list(string)
    }))

    default = []
}