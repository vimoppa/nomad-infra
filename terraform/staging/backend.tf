terraform {
  backend "gcs" {
    bucket = "ucontex-app-remote-state"
    prefix = "terraform/state"
  }
}
