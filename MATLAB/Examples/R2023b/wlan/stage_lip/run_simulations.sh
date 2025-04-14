#!/bin/bash

# Define the range of arrival rates (100, 200, ..., 10000)
arrival_rates=$(seq 100 100 10000)

# Run MATLAB script for each arrival rate
for rate in $arrival_rates; do
    echo "*** Running simulation for arrival rate: $rate"
    matlab -batch "simulate(\"$rate\")"
done

echo "All simulations completed!"
