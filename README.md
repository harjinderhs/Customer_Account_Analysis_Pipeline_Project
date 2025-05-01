# 🔷 Customer Insights at Scale: Modern Data Pipeline with Azure ADF & Medallion Architecture

Welcome to the repository for my **Azure Data Engineering** project that demonstrates how to build a production-ready, scalable data pipeline using **Azure Data Factory (ADF)** and the **Medallion Architecture**.

This project processes customer financial data from raw ingestion to interactive business reporting using Azure technologies.

---

## 📂 Source Data

This project uses sample **on-premise CSV files** as input:

- `accounts.csv`
- `customers.csv`
- `loan_payments.csv`
- `loans.csv`
- `transactions.csv`

---

## 🏗️ Architecture Overview

### ✅ Bronze Layer – *Raw Ingestion*
- Ingested data from local storage using **Self-hosted Integration Runtime**
- Data copied to **Azure Data Lake Storage Gen2 (ADLS Gen2)** using ADF’s **Copy Activity**

### ✅ Silver Layer – *Clean & Transform*
- Data cleaning and schema transformation with **Mapping Data Flows**
- Cleaned data stored in the Silver layer of **ADLS Gen2**

### ✅ Gold Layer – *Business Logic & Historical Tracking*
- Final outputs loaded to **Azure SQL Database**
- Implemented:
  - 🔁 **SCD Type 2** for `accounts` and `customers` — to track historical changes like status updates or address changes
  - 🔄 **SCD Type 1** for `loans`, `loan_payments`, and `transactions` — for real-time updates where history is not essential

---

## 📊 Analytics & Reporting

- Built interactive dashboards using **Power BI**
- Reports published to **Microsoft Fabric** for centralized access and collaboration
- Applied **data modeling** techniques for optimized performance and user experience

---

## ⚙️ Tech Stack

- Azure Data Factory (ADF)
- Azure Data Lake Storage Gen2 (ADLS Gen2)
- Azure SQL Database
- Power BI
- Microsoft Fabric
- Mapping Data Flows
- Linked Services
- Self-hosted Integration Runtime
- Medallion Architecture
- SCD Type 1 & Type 2 Implementation

---

## 📸 Architecture Diagram

*Check the repo for the full architecture visualization.*

---

## 📑 Documentation

Full step-by-step implementation guide is available in Repo for:
- ADF pipeline creation
- Medallion layering
- SCD logic implementation
- Power BI integration
- Deployment to Microsoft Fabric
