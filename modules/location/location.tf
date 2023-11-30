resource "aws_location_place_index" "geocoder" {
  data_source   = "Here"
  index_name    = "geocoder"
  data_source_configuration {
    intended_use  = "Storage"
  }
}

output "index_name" {
  description = "The location index name"
  value       = aws_location_place_index.geocoder.index_name
}