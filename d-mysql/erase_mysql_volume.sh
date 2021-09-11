#!/bin/bash

docker container prune -f
docker volume rm stormy_mysql_data
