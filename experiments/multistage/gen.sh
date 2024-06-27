#!/bin/bash

docker buildx build  -t build2 --sbom=true --provenance=true .