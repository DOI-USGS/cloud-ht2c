#!/bin/bash

function main() {
  local token
  local instance_id
  token=$( curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" )
  instance_id=$( curl -H "X-aws-ec2-metadata-token: ${token}" -v http://169.254.169.254/latest/meta-data/instance-id )

  aws autoscaling terminate-instance-in-auto-scaling-group \
    --instance-id "${instance_id}" \
    --should-decrement-desired-capacity
}

main "$@"
