#!/bin/bash
# Script to delete the queue managers in the uniform cluster, this may be three 
# or four queue managers

#docker stop QM1
docker stop QM1
docker rm QM1
docker volume rm qm1UCdata

#docker stop QM2
docker stop QM2
docker rm QM2
docker volume rm qm2UCdata

#docker stop QM3
docker stop QM3
docker rm QM3
docker volume rm qm3UCdata

#docker stop QM4
docker stop QM4
docker rm QM4
docker volume rm qm4UCdata

docker network rm mqnetwork
