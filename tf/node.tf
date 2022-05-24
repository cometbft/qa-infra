resource "google_compute_address" "static" {
  name = "ipv4-address"
  region  = "europe-west6"
}

data "google_compute_image" "centos_image" {
  family  = "centos-7"
  project = "centos-cloud"
}

resource "google_compute_disk" "default" {
  name  = "evmos-disk"
  type  = "pd-standard"
  zone  = "europe-west6-a"
  size  = "200"
}


resource "google_compute_instance" "instance" {
  name         = "evmos-validator"
  machine_type = "e2-standard-4"
  zone         = "europe-west6-a"
  tags = ["evmos"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  attached_disk {
    source = google_compute_disk.default.self_link
    device_name = "evmos_disk"
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.static.address
    }
  }
}

