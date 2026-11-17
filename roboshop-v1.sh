#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro" 
domain_name="daws99.store"
hosted_zone_id="Z0502381KZWBJSRZWZ1O"

for instance in $@
do
    echo "Creating instance: $instance"  
done