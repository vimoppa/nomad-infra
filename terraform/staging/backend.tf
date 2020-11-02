terraform {
  backend "gcs" {
    bucket = "ucontext-app-remote-state"
    prefix = "tf-backend"
  }
}
