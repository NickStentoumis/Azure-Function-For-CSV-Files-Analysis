# Dataset Analysis Using Azure Functions

This script leverages a cloud solution and more specificaly Azure funtions in order to extract stats from a CSV dataset. 

## Script Analysis

The function is blob triggered, meaning that once a dataset is uploaded to a storage account the script is triggered and executed. 

Script takes as input the dataset that triggered its execution. Then in a foreach loop it processes every line of the CSV file in order to extract stats. Since all the processing is done in a loop this is not a vaible solution for very large datasets if only one funtion is used. Alternative to this, could be to trigger multiple Azure function and each one of the functions to process a chunk of the original dataset.

Once the processing is done, results are exported to CSV files and uploaded to blob storage. A log file describing the execution of the script is also uploaded to storage. 

## Dataset
The dataset contains records of taxi rides in New York City. The queries the script answers are the ones described below. 

* Calculate the number of rides start in each quarter, given the fact that we split the City in quarters around a given spot. 

* Print the routes which were longer than one kilometre and with a cost greater than $10 and with more than two customers.

* For the routes of the query described above, find the five most popular timestamps for the pickup and the most popular quarters. 

* Given a pair of coordinates, find the number of rides that started in a five km radius from that spot and costed more than 10$

These queries are only a glimpse of what could be extracted from the dataset.

The CSV file is structured as presented below.

key, fare_amount, pickup_datetime, pickup_longitude, pickup_latitude, dropoff_longitude dropoff_latitude, passenger_count

26:21.0, 4.5, 2009-06-15 17:26:21 UTC, -73.844311, 40.721319, -73.84161, 40.712278,	1



