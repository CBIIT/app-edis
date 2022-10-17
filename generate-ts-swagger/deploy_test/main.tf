
resource "null_resource" "swagger" {
  provisioner "local-exec" {
    command = "npm run swagger"
    working_dir = "../"
  }
}

resource "null_resource" "lambda-zip" {
  depends_on = [null_resource.swagger]
  provisioner "local-exec" {
    command = "npm run zip-prod"
    working_dir = "../"
  }
}
