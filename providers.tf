/* Set few aliases on the provider and region so we can setup DR clusters */
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