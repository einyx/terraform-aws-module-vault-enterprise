provider "aws" {
  alias  = "dr"
  region = "${ var.dr_region }"
}

provider "aws" {
  alias  = "active"
  region = "${ var.region }"
}

provider "aws" {
  region = "${ var.region }"
}