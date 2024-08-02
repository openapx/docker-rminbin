#!/bin/bash


# -- install any updates 
apt-get update -y

# -- install any binary library dependenceis
apt-get install $(grep "^[^#;]" /opt/openapx/config/rminbin/libs | tr '\n' ' ') -y --no-install-recommends


