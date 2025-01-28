<!--
Copyright (c) 2010 Yahoo! Inc., 2012 - 2016 YCSB contributors.
All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You
may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License. See accompanying
LICENSE file.
-->
# YCSB-IVS: Benchmarking Databases with Varying Value Sizes  

YCSB-IVS introduces a novel benchmarking technique to evaluate database performance as value sizes vary over time. This enhancement builds on the original YCSB framework, enabling experiments with dynamic value size growth and providing new insights into database behavior under evolving workloads.  

## Overview  

Our benchmarking approach evaluates three widely-used databases:  
- **MongoDB**  
- **MariaDB + InnoDB**  
- **MariaDB + RocksDB**  

### Key Features  
- Analysis of database performance under dynamic value size variations.  
- Comparison of latency, throughput, and scalability across different database systems.  
- Comprehensive scripts and figures for replicating our analysis.  

## Cloning Details  

To get started, clone the YCSB-IVS repository:  
```bash
git clone https://github.com/dliyanage/YCSB-IVS.git
cd YCSB-IVS
```  

## Repository Structure  

| Directory                  | Description                                                                 |
|----------------------------|-----------------------------------------------------------------------------|
| **`./experiment_scripts`** | Bash scripts for running workload experiments.                             |
| **`./analysis/Data`**      | Output data files relevant for analysis. Refer to `./analysis/README.md`.  |
| **`./Scripts`**            | Analysis scripts written in R (Jupyter notebooks).                         |
| **`./Figures`**            | Generated output figures and visualizations referenced in our paper.       |  

## Experimental Scripts  

The `./experiment_scripts` directory contains all the necessary bash scripts for running workload experiments and saving the results as CSV files.  

#### Examples:  
- **MongoDB Workload**:  
  Use the `./experiment_scripts/experiment_mongodb.sh` script to execute the benchmarking workloads in MongoDB with varying value sizes.  
- **MongoDB Baseline**:  
  Use the `./experiment_scripts/experiment_mongodb_baseline.sh` script to run baseline executions with fixed value sizes for comparison. 

Please refer to the general instructions on configuring experiments in the README file at `./experiment_scripts/README.md`. 

## Analysis Data  

All output files generated during experiments are stored in the `./analysis/Data` directory. These files are prepared for analysis and visualization.  

To understand the analysis process and view results, refer to the [README.md](./analysis/README.md) within the `./analysis` directory. This document provides step-by-step details on our analysis methodology and generates outputs included in our publication.  

## Analysis Workflow  

The R notebook located in the **`./Scripts`** folder includes:  
- Step-by-step explanations of our analysis process.  
- Intermediate results and final output figures.  

## How to Use This Repository  

1. **Clone the repository**:  
   ```bash
   git clone https://github.com/dliyanage/YCSB-IVS.git
   cd YCSB-IVS
   ```  

2. **Explore the data**:  
   Navigate to the `./Data` directory to view raw data files.  

3. **Run the analysis**:  
   Open the R notebook in the `./Scripts` folder to reproduce the analysis and figures.  

4. **View results**:  
   Output figures are stored in the `./Figures` directory.  

## Citation  

If you use this work, please cite:  
**Benchmarking Databases with Varying Value Sizes [Experiment, Analysis, and Benchmark]." VLDB 2025.**  

For further information, visit the [YCSB-IVS GitHub repository](https://github.com/dliyanage/YCSB-IVS).  

---  

YCSB-IVS expands the capabilities of the original YCSB framework to simulate realistic scenarios of value size growth, offering a powerful tool for evaluating database scalability and performance.

=============================================================
=============================================================

## README from the original authors

YCSB
====================================
[![Build Status](https://travis-ci.org/brianfrankcooper/YCSB.png?branch=master)](https://travis-ci.org/brianfrankcooper/YCSB)



Links
-----
* To get here, use https://ycsb.site
* [Our project docs](https://github.com/brianfrankcooper/YCSB/wiki)
* [The original announcement from Yahoo!](https://labs.yahoo.com/news/yahoo-cloud-serving-benchmark/)

Getting Started
---------------

1. Download the [latest release of YCSB](https://github.com/brianfrankcooper/YCSB/releases/latest):

    ```sh
    curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz
    tar xfvz ycsb-0.17.0.tar.gz
    cd ycsb-0.17.0
    ```
    
2. Set up a database to benchmark. There is a README file under each binding 
   directory.

3. Run YCSB command. 

    On Linux:
    ```sh
    bin/ycsb.sh load basic -P workloads/workloada
    bin/ycsb.sh run basic -P workloads/workloada
    ```

    On Windows:
    ```bat
    bin/ycsb.bat load basic -P workloads\workloada
    bin/ycsb.bat run basic -P workloads\workloada
    ```

  Running the `ycsb` command without any argument will print the usage. 
   
  See https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  for a detailed documentation on how to run a workload.

  See https://github.com/brianfrankcooper/YCSB/wiki/Core-Properties for 
  the list of available workload properties.


Building from source
--------------------

YCSB requires the use of Maven 3; if you use Maven 2, you may see [errors
such as these](https://github.com/brianfrankcooper/YCSB/issues/406).

To build the full distribution, with all database bindings:

    mvn clean package

To build a single database binding:

    mvn -pl site.ycsb:mongodb-binding -am clean package
