
resource "build" "swagger" {
  provisioner "local-exec" {
    command = "npm run swagger"
    working_dir = "../"
  }
}

resource "build" "lambda-zip" {
  provisioner "local-exec" {
    command = "npm run zip-prod"
    working_dir = "../"
  }
}
