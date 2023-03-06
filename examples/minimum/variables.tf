variable "name" {
  description = " Friendly name of the new secret. The secret name can consist of uppercase letters, lowercase letters, digits, and any of the following characters: /_+=.@- Conflicts with name_prefix."
  type        = string
  default     = "example-minimum-secret"
}

variable "secret_description" {
  description = " Description of the secret."
  type        = string
  default     = "Example minimum secret"
}

variable "tags" {
  description = " A map of tags to assign to the object. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default = {
    Name               = "example-minimum-secret"
    Environment        = "example"
    "user::CostCenter" = "terraform-registry"
    Department         = "DevOps"
    Project            = "Examples"
    Owner              = "Boldlink"
    LayerName          = "Example"
    LayerId            = "Example"
  }
}
