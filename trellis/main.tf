/*
|--------------------------------------------------------------------------
| Project Configuration
|--------------------------------------------------------------------------
|
|
*/

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project
  region  = var.region
  zone    = var.zone
}


resource "google_compute_project_metadata" "default" {
    metadata = {
        trellis-network = google_compute_network.trellis-vpc-network.name
        trellis-subnetwork = google_compute_subnetwork.trellis-subnet.name
    }
}
