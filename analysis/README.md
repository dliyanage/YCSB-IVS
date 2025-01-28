# Analysis of Workload Experimental Data with YCSB: Impact of Varying Value Sizes - VLDB 2025  

This repository contains the data, scripts, and visualizations from our study presented at VLDB 2025, where we investigated database performance under varying value sizes using an enhanced version of YCSB, named [YCSB-IVS](https://github.com/dliyanage/YCSB-IVS) (**YCSB - Increasing Value Sizes**).  

## Overview  
Our benchmarking introduces a novel technique applied to three widely-used databases:  
- **MongoDB**  
- **MariaDB + InnoDB**  
- **MariaDB + RocksDB**  

### Key Features  
- Analysis of database performance under dynamic value size variations.  
- Comparison of latency, throughput, and scalability across different database systems.  
- Comprehensive scripts and figures for replicating our analysis.  

## Repository Structure  

| Directory          | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| **`./Data`**       | Raw experimental data used in our study.                                   |
| **`./Scripts`**    | Analysis scripts written in R (Jupyter notebooks).                         |
| **`./Figures`**    | Generated output figures and visualizations referenced in our paper.       |

## Analysis Workflow  
The R notebook located in the **`./Scripts`** folder includes:  
- Step-by-step explanations of our analysis process.  
- Intermediate results and final output figures.  

## How to Access This Repository  
**Clone the repository**:  
   ```bash
   git clone https://github.com/dliyanage/YCSB-IVS.git
   cd YCSB-IVS/analysis

