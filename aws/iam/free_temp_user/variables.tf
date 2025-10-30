variable "username" {
  description = "Username for the free tier user"
  type        = string
  default     = "ft"
}

variable "access_expiry" {
  description = "Access expiry time in ISO 8601 format (e.g., 2024-01-15T23:59:59Z)"
  type        = string
  default     = ""
}

variable "auto_cleanup" {
  description = "Enable automatic cleanup after expiry"
  type        = bool
  default     = false
}