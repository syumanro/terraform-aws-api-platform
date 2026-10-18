# Preserve existing public networking when upgrading from the previous layout.
moved {
  from = aws_subnet.nlb_a
  to   = aws_subnet.public_a
}

moved {
  from = aws_subnet.nlb_c
  to   = aws_subnet.public_c
}

moved {
  from = aws_route_table.nlb_public
  to   = aws_route_table.public
}

moved {
  from = aws_route_table_association.nlb_a
  to   = aws_route_table_association.public_a
}

moved {
  from = aws_route_table_association.nlb_c
  to   = aws_route_table_association.public_c
}
