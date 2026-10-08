# Food Supply Chain Management System

A lightweight, reliable, read-only Streamlit dashboard backed by MySQL for monitoring agricultural supply chains, tracking warehouse and retail inventory, calculating batch shelf life, and visualizing market demand.

---

## Project Description

The **Food Supply Chain Management System** provides an operational dashboard for multi-tier food supply networks. It connects directly to a MySQL database to aggregate inventory data across wholesalers and retailers, tracks expiration dynamics, and displays master records for farmers, crops, wholesalers, and retail partners.

The application is strictly **read-only**, executing exclusively `SELECT` queries to ensure zero modification risk to production data.

---

## Features

- **Supply Chain Overview**: High-level KPI metrics displaying total farmer, wholesaler, retailer, and crop counts alongside total inventory in kilograms.
- **Inventory Distribution Visualizations**: Native Streamlit charts visualizing stock volume broken down by crop and distribution channel (Wholesaler vs. Retailer).
- **Consolidated Inventory Management**: Unified view merging wholesaler and retailer warehouse records with partner identity, location, and crop details.
- **Automated Expiry Classification**: Dynamic batch shelf-life calculation categorizing stock into fresh, near-expiry, expired, or unknown status based on calendar date.
- **Multi-Parameter Inventory Filtering**: Granular filtering across channel, crop name, city, and expiry status with real-time record count feedback.
- **Master Data Directory**: Tabular inspection of core master entities (Farmers, Wholesalers, Retailers, and Crops).
- **Optional Demand Analysis**: Historical transaction volume analysis by crop acting as an indicator for market demand when transaction data is available.

---

## Technology

- **Python** (>= 3.9)
- **Streamlit**: Web interface and visualization framework
- **Pandas**: In-memory data processing, shaping, and status categorization
- **MySQL**: Relational data store
- **mysql-connector-python**: Pure-Python MySQL database driver

---

## Project Structure

```text
Food-Supply-Chain-Management-System/
├── .env.example          # Environment variable template for database credentials
├── .gitignore            # Git exclusion rules for virtualenvs, caches, and secrets
├── README.md             # Project documentation and setup guide
├── app.py                # Main Streamlit dashboard application
├── requirements.txt      # Project dependencies
└── sql/
    ├── schema.sql        # Core relational database schema
    ├── schema_updates.sql# Extended views, procedures, and triggers
    └── sample_data.sql   # Reproducible seed data for testing
```

---

## Database Requirements

### Core Required Tables

The dashboard requires the following tables defined in `sql/schema.sql`:

- `CROP`: Master list of crops with shelf-life and pricing metadata.
- `FARMER`: Agricultural producer profiles and regional locations.
- `WHOLESALER`: Distribution partner profiles and facility locations.
- `RETAILER`: Retail store profiles and city locations.
- `WHOLESALER_STOCK`: Bulk inventory held by wholesalers.
- `RETAIL_STOCK`: Commercial inventory held by retail outlets.

### Optional Tables

- `TRANSACTIONS`: When present with `crop_id` and `quantity`, the dashboard aggregates total volume per crop as a demand proxy. If absent, the dashboard skips this section gracefully without error.

---

## Schema Compatibility

The database schema includes both a core relational schema (`sql/schema.sql`) and an extended migration script (`sql/schema_updates.sql`). 

To ensure maximum resilience and simplicity:
- The dashboard queries stable common fields directly from `WHOLESALER_STOCK`, `RETAIL_STOCK`, `CROP`, `WHOLESALER`, and `RETAILER`.
- The dashboard intentionally avoids hard dependencies on optional database views (`v_production_pricing`, `v_wholesaler_stock_pricing`), stored procedures, or triggers.
- The application executes reliably regardless of whether optional stored routines are installed.

---

## Expiry Rules

Shelf-life status is computed dynamically in Python by comparing each batch's `expiry_date` against the current date:

| Status | Condition |
| :--- | :--- |
| **Expired** | Expiry date is strictly before today (`days_to_expiry < 0`) |
| **Near expiry** | Between 0 and 30 days remaining (`0 <= days_to_expiry <= 30`) |
| **Fresh** | More than 30 days remaining (`days_to_expiry > 30`) |
| **Unknown** | Expiry date is missing, null, or unparseable |

---

## Read-Only Behavior

The application is engineered strictly for monitoring and analysis. It never issues:
- `INSERT`
- `UPDATE`
- `DELETE`
- `DROP`
- `ALTER`
- `CREATE`

All data interactions occur via standard `SELECT` queries, ensuring safe execution even when connected with read-only database accounts.

---

## Installation

### 1. Clone or Open the Repository

```bash
git clone <repository_url>
cd Food-Supply-Chain-Management-System
```

### 2. Create a Virtual Environment

**Windows (PowerShell):**
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

**macOS / Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## Database Configuration

The application reads database connection parameters using the following precedence:
1. **Streamlit Secrets** (`.streamlit/secrets.toml`)
2. **Environment Variables** (`.env` or system environment)
3. **Interactive Sidebar Inputs** in the Streamlit application

### Configuration Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `DB_HOST` | MySQL server host address | `localhost` |
| `DB_PORT` | MySQL server port | `3306` |
| `DB_USER` | MySQL username | `root` |
| `DB_PASSWORD` | MySQL password | `""` |
| `DB_NAME` | MySQL database name | `smart_food_supply` |

### Setting Up Environment Variables

Copy `.env.example` to `.env` (or configure your shell):

```bash
cp .env.example .env
```

Edit `.env` with your MySQL database credentials.

### Initializing the Database

To set up the database and load seed data:

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p < sql/sample_data.sql
```

---

## Run Command

Launch the Streamlit web application:

```bash
streamlit run app.py
```

The application will start and open automatically in your browser at `http://localhost:8501`.

---

## Dashboard Layout

The dashboard is structured into four primary sections:

1. **Overview**: Key metric cards for counts of farmers, wholesalers, retailers, crops, and total stock volume, followed by distribution bar charts by crop and channel.
2. **Demand Analysis**: Optional bar chart displaying total transacted volume per crop as a demand indicator when transaction history exists.
3. **Inventory**: Comprehensive stock listing combining wholesaler and retailer inventories with filtering controls for Channel, Crop, City, and Expiry Status.
4. **Master Data**: Four distinct tabs (`Farmers`, `Wholesalers`, `Retailers`, `Crops`) for inspecting master reference tables.
