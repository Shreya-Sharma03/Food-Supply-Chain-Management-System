import datetime
import os
import mysql.connector
import pandas as pd
import streamlit as st


# ==============================================================================
# 1. DATABASE CONFIGURATION & CONNECTION
# ==============================================================================

def load_dotenv_simple(filepath=".env"):
    """Loads key-value pairs from a local .env file into os.environ if present."""
    if os.path.exists(filepath):
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        k = k.strip()
                        v = v.strip().strip("'").strip('"')
                        if k not in os.environ:
                            os.environ[k] = v
        except Exception:
            pass


load_dotenv_simple()


def get_setting(key, default=""):
    """
    Reads configuration values following priority:
    1. Streamlit secrets (if defined)
    2. Environment variables
    3. Default fallback value
    """
    try:
        if key in st.secrets:
            return str(st.secrets[key])
    except Exception:
        pass
    return os.environ.get(key, default)


def connect_db(host, port, user, password, database):
    """
    Establishes a MySQL database connection.
    Returns the connection object, or None if connection fails.
    """
    try:
        connection = mysql.connector.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            database=database
        )
        return connection
    except mysql.connector.Error as err:
        st.error(f"Database Connection Error: {err.msg}")
        return None


def run_query(conn, query, params=None):
    """
    Executes a read-only SELECT query and returns the results as a Pandas DataFrame.
    Guarantees no data-modifying statements are executed.
    """
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        records = cursor.fetchall()
        return pd.DataFrame(records)
    finally:
        cursor.close()


# ==============================================================================
# 2. DATA PROCESSING & STATUS CALCULATION
# ==============================================================================

def add_status_columns(df):
    """
    Calculates expiry status for each inventory batch using today's date:
    - Expired: expiry date is before today (days < 0)
    - Near expiry: 0 to 30 days remaining (0 <= days <= 30)
    - Fresh: more than 30 days remaining (days > 30)
    - Unknown: expiry date missing or invalid
    """
    if df.empty or "expiry_date" not in df.columns:
        df["days_to_expiry"] = None
        df["status"] = "Unknown"
        return df

    today = datetime.date.today()
    days_to_expiry_list = []
    status_list = []

    for exp in df["expiry_date"]:
        if pd.isna(exp):
            days_to_expiry_list.append(None)
            status_list.append("Unknown")
            continue

        # Parse date representation safely
        if isinstance(exp, str):
            try:
                exp_date = datetime.datetime.strptime(exp, "%Y-%m-%d").date()
            except ValueError:
                days_to_expiry_list.append(None)
                status_list.append("Unknown")
                continue
        elif isinstance(exp, pd.Timestamp):
            exp_date = exp.date()
        elif isinstance(exp, datetime.datetime):
            exp_date = exp.date()
        elif isinstance(exp, datetime.date):
            exp_date = exp
        else:
            days_to_expiry_list.append(None)
            status_list.append("Unknown")
            continue

        days_remaining = (exp_date - today).days
        days_to_expiry_list.append(days_remaining)

        if days_remaining < 0:
            status_list.append("Expired")
        elif days_remaining <= 30:
            status_list.append("Near expiry")
        else:
            status_list.append("Fresh")

    df["days_to_expiry"] = days_to_expiry_list
    df["status"] = status_list
    return df


def load_data(conn):
    """
    Loads all data required by the dashboard using simple SELECT statements.
    """
    # Wholesaler inventory
    wholesaler_stock_query = """
    SELECT
        ws.id,
        w.name AS partner_name,
        w.city,
        c.name AS crop_name,
        ws.quantity_kg,
        ws.expiry_date
    FROM WHOLESALER_STOCK ws
    JOIN WHOLESALER w ON w.id = ws.wholesaler_id
    JOIN CROP c ON c.id = ws.crop_id;
    """
    df_wholesaler = run_query(conn, wholesaler_stock_query)
    df_wholesaler["channel"] = "Wholesaler"

    # Retailer inventory
    retail_stock_query = """
    SELECT
        rs.id,
        r.name AS partner_name,
        r.city,
        c.name AS crop_name,
        rs.quantity_kg,
        rs.expiry_date
    FROM RETAIL_STOCK rs
    JOIN RETAILER r ON r.id = rs.retailer_id
    JOIN CROP c ON c.id = rs.crop_id;
    """
    df_retail = run_query(conn, retail_stock_query)
    df_retail["channel"] = "Retailer"

    # Combine into unified inventory DataFrame
    df_inventory = pd.concat([df_wholesaler, df_retail], ignore_index=True)
    if not df_inventory.empty:
        df_inventory["quantity_kg"] = pd.to_numeric(df_inventory["quantity_kg"], errors="coerce").fillna(0.0)

    # Add days_to_expiry and status
    df_inventory = add_status_columns(df_inventory)

    # Master counts for Overview metrics
    farmers_count = run_query(conn, "SELECT COUNT(*) AS total FROM FARMER;")["total"].iloc[0]
    wholesalers_count = run_query(conn, "SELECT COUNT(*) AS total FROM WHOLESALER;")["total"].iloc[0]
    retailers_count = run_query(conn, "SELECT COUNT(*) AS total FROM RETAILER;")["total"].iloc[0]
    crops_count = run_query(conn, "SELECT COUNT(*) AS total FROM CROP;")["total"].iloc[0]

    # Optional demand proxy (TRANSACTIONS table)
    df_transactions = None
    try:
        tx_query = """
        SELECT
            c.name AS crop_name,
            SUM(t.quantity) AS total_quantity
        FROM TRANSACTIONS t
        JOIN CROP c ON c.id = t.crop_id
        GROUP BY c.name
        ORDER BY total_quantity DESC;
        """
        df_transactions = run_query(conn, tx_query)
    except Exception:
        # Transactions table is optional; skip if absent
        df_transactions = None

    # Master data tables
    df_farmers = run_query(conn, "SELECT id, name, city, state, contact FROM FARMER ORDER BY id;")
    df_wholesalers_master = run_query(conn, "SELECT id, name, city, state, contact FROM WHOLESALER ORDER BY id;")
    df_retailers_master = run_query(conn, "SELECT id, name, city, state, contact FROM RETAILER ORDER BY id;")
    df_crops_master = run_query(conn, "SELECT id, name, category, base_price_per_kg, shelf_life_days FROM CROP ORDER BY id;")

    return {
        "inventory": df_inventory,
        "metrics": {
            "farmers": farmers_count,
            "wholesalers": wholesalers_count,
            "retailers": retailers_count,
            "crops": crops_count,
            "total_inventory": df_inventory["quantity_kg"].sum() if not df_inventory.empty else 0.0
        },
        "transactions": df_transactions,
        "master_data": {
            "farmers": df_farmers,
            "wholesalers": df_wholesalers_master,
            "retailers": df_retailers_master,
            "crops": df_crops_master
        }
    }


# ==============================================================================
# 3. STREAMLIT APPLICATION ENTRY POINT
# ==============================================================================

def main():
    st.set_page_config(
        page_title="Food Supply Chain Management System",
        layout="wide"
    )

    st.title("Food Supply Chain Management System")
    st.markdown("Real-time read-only dashboard for monitoring crops, inventory, and supply chain partners.")

    # Hide Streamlit's default "Deploy" button and footer for a clean dashboard appearance
    st.markdown(
        """
        <style>
        .stDeployButton {display: none !important;}
        footer {visibility: hidden;}
        </style>
        """,
        unsafe_allow_html=True
    )

    # --- Sidebar: Database Configuration ---
    st.sidebar.header("System Settings")

    default_host = get_setting("DB_HOST", "localhost")
    default_port = int(get_setting("DB_PORT", "3306"))
    default_user = get_setting("DB_USER", "root")
    default_password = get_setting("DB_PASSWORD", "")
    default_database = get_setting("DB_NAME", "smart_food_supply")

    # Provide connection fields in a collapsible expander to keep the sidebar uncluttered
    with st.sidebar.expander("Database Settings", expanded=not bool(default_password)):
        sidebar_host = st.text_input("Host", value=default_host)
        sidebar_port = st.number_input("Port", value=default_port, step=1)
        sidebar_user = st.text_input("User", value=default_user)
        sidebar_password = st.text_input("Password", value=default_password, type="password")
        sidebar_database = st.text_input("Database", value=default_database)

    conn = connect_db(
        host=sidebar_host,
        port=int(sidebar_port),
        user=sidebar_user,
        password=sidebar_password,
        database=sidebar_database
    )

    if conn is None:
        st.sidebar.error("Database Disconnected")
        st.stop()
        return

    st.sidebar.success(f"Connected: `{sidebar_database}`")

    # Load data safely from MySQL
    data = load_data(conn)
    conn.close()

    df_inventory = data["inventory"]
    metrics = data["metrics"]

    # ==============================================================================
    # 4. OVERVIEW SECTION
    # ==============================================================================

    st.header("Overview")

    # Five summary metric cards
    col1, col2, col3, col4, col5 = st.columns(5)
    col1.metric("Farmers", metrics["farmers"])
    col2.metric("Wholesalers", metrics["wholesalers"])
    col3.metric("Retailers", metrics["retailers"])
    col4.metric("Crops", metrics["crops"])
    col5.metric("Total Inventory (kg)", f"{metrics['total_inventory']:,.2f}")

    st.write("")

    # Two simple Streamlit bar charts
    chart_col1, chart_col2 = st.columns(2)

    with chart_col1:
        st.subheader("Inventory Quantity by Crop")
        if not df_inventory.empty:
            crop_chart_data = (
                df_inventory.groupby("crop_name")["quantity_kg"]
                .sum()
                .sort_values(ascending=False)
            )
            st.bar_chart(crop_chart_data)
        else:
            st.info("No inventory data available to chart.")

    with chart_col2:
        st.subheader("Inventory Quantity by Channel")
        if not df_inventory.empty:
            channel_chart_data = (
                df_inventory.groupby("channel")["quantity_kg"]
                .sum()
            )
            st.bar_chart(channel_chart_data)
        else:
            st.info("No channel data available to chart.")

    # ==============================================================================
    # 5. DEMAND ANALYSIS (OPTIONAL TRANSACTIONS PROXY)
    # ==============================================================================

    st.write("---")
    st.header("Demand Analysis")

    df_transactions = data["transactions"]
    if df_transactions is not None and not df_transactions.empty:
        st.subheader("Transaction Volume by Crop (Demand Proxy)")
        st.caption("Historical transaction volume indicator representing market demand proxy.")
        tx_chart_data = df_transactions.set_index("crop_name")["total_quantity"]
        st.bar_chart(tx_chart_data)
    else:
        st.info("The TRANSACTIONS table is not available or contains no records. Transaction volume analysis is skipped.")

    # ==============================================================================
    # 6. INVENTORY SECTION & FILTERS
    # ==============================================================================

    st.write("---")
    st.header("Inventory")

    if df_inventory.empty:
        st.info("No inventory records found in the database.")
    else:
        # Filter dropdowns
        filter_col1, filter_col2, filter_col3, filter_col4 = st.columns(4)

        channel_options = ["All"] + sorted(df_inventory["channel"].dropna().unique().tolist())
        crop_options = ["All"] + sorted(df_inventory["crop_name"].dropna().unique().tolist())
        city_options = ["All"] + sorted(df_inventory["city"].dropna().unique().tolist())
        status_options = ["All", "Fresh", "Near expiry", "Expired", "Unknown"]

        with filter_col1:
            selected_channel = st.selectbox("Channel", channel_options)
        with filter_col2:
            selected_crop = st.selectbox("Crop", crop_options)
        with filter_col3:
            selected_city = st.selectbox("City", city_options)
        with filter_col4:
            selected_status = st.selectbox("Expiry status", status_options)

        # Apply filters
        filtered_df = df_inventory.copy()

        if selected_channel != "All":
            filtered_df = filtered_df[filtered_df["channel"] == selected_channel]

        if selected_crop != "All":
            filtered_df = filtered_df[filtered_df["crop_name"] == selected_crop]

        if selected_city != "All":
            filtered_df = filtered_df[filtered_df["city"] == selected_city]

        if selected_status != "All":
            filtered_df = filtered_df[filtered_df["status"] == selected_status]

        # Required display columns
        display_columns = [
            "id",
            "channel",
            "partner_name",
            "city",
            "crop_name",
            "quantity_kg",
            "expiry_date",
            "days_to_expiry",
            "status"
        ]

        st.write(f"Showing **{len(filtered_df)}** of **{len(df_inventory)}** inventory records.")
        st.dataframe(filtered_df[display_columns], use_container_width=True)

    # ==============================================================================
    # 7. MASTER DATA SECTION
    # ==============================================================================

    st.write("---")
    st.header("Master Data")

    tab_farmers, tab_wholesalers, tab_retailers, tab_crops = st.tabs(
        ["Farmers", "Wholesalers", "Retailers", "Crops"]
    )

    with tab_farmers:
        st.subheader("Farmers")
        st.dataframe(data["master_data"]["farmers"], use_container_width=True)

    with tab_wholesalers:
        st.subheader("Wholesalers")
        st.dataframe(data["master_data"]["wholesalers"], use_container_width=True)

    with tab_retailers:
        st.subheader("Retailers")
        st.dataframe(data["master_data"]["retailers"], use_container_width=True)

    with tab_crops:
        st.subheader("Crops")
        st.dataframe(data["master_data"]["crops"], use_container_width=True)


if __name__ == "__main__":
    main()
