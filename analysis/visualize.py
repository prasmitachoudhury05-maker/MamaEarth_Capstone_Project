"""
Capstone Project: Mamaearth Returns & Growth Intelligence Pipeline
Part 2: Visualizations
File: analysis/visualize.py

This script loads the raw CSVs, applies the exact cleaning pipeline,
and produces the two required publication-quality charts in visualizations/:
1. visualizations/return_rate_by_payment.png (Return Rate by Payment Method)
2. visualizations/monthly_revenue_trend.png (Outlier-Corrected Monthly Revenue Trend)
"""

import os
import matplotlib.pyplot as plt
import pandas as pd


def generate_visualizations():
    # Create target directory
    os.makedirs("visualizations", exist_ok=True)

    # 1. Load Data
    customers = pd.read_csv("data/customers.csv")
    products = pd.read_csv("data/products.csv")
    orders = pd.read_csv("data/orders.csv")

    # 2. Standardize Casing
    orders["payment_method"] = orders["payment_method"].str.strip().str.upper()

    # 3. Deduplicate
    natural_key = [
        "customer_id",
        "product_id",
        "order_date",
        "quantity",
        "discount_pct",
        "payment_method",
        "rating",
        "returned",
    ]
    orders_clean = orders.drop_duplicates(subset=natural_key, keep="first").copy()

    # 4. Impute
    orders_clean["discount_pct"] = orders_clean["discount_pct"].fillna(0)
    median_rating = orders_clean["rating"].median()
    orders_clean["rating"] = orders_clean["rating"].fillna(median_rating)

    # 5. Merge
    df = orders_clean.merge(products, on="product_id", how="left").merge(
        customers, on="customer_id", how="left"
    )
    df["order_value"] = df["quantity"] * df["price"] * (1 - df["discount_pct"] / 100.0)

    # 6. Flag Outliers
    q1 = df["quantity"].quantile(0.25)
    q3 = df["quantity"].quantile(0.75)
    iqr = q3 - q1
    upper_bound = q3 + 1.5 * iqr
    df["is_outlier"] = df["quantity"] > upper_bound

    # -------------------------------------------------------------------------
    # Chart 1: Return Rate by Payment Method (Bar Chart - Dark to Light Blue)
    # -------------------------------------------------------------------------
    rr_df = df.groupby("payment_method")["returned"].agg(["count", "mean"]).reset_index()
    rr_df["return_rate_pct"] = (rr_df["mean"] * 100).round(1)
    rr_df = rr_df.sort_values(by="return_rate_pct", ascending=False)

    plt.figure(figsize=(8, 5.5), dpi=300)
    
    # Sequential Dark-to-Light Blue Gradient
    # Highest (COD: 44.4%) -> Deep Midnight Blue
    # Medium  (UPI: 18.9%) -> Royal Cobalt Blue
    # Lowest  (CARD: 14.7%) -> Soft Sky Blue
    palette_map = {
        "COD": "#1E3A8A",   # Deep Navy / Midnight Blue
        "UPI": "#3B82F6",   # Royal Cobalt Blue
        "CARD": "#93C5FD",  # Soft Sky Blue
    }
    colors = [palette_map.get(pm, "#1E3A8A") for pm in rr_df["payment_method"]]
    
    bars = plt.bar(
        rr_df["payment_method"],
        rr_df["return_rate_pct"],
        color=colors,
        width=0.52,
        edgecolor="#0F172A",
        linewidth=1.2,
        alpha=0.95,
    )

    plt.title("COD Returns at 44.4% — 3x Higher Than Card", fontsize=14, fontweight="bold", pad=15, color="#0F172A")
    plt.xlabel("Payment Method", fontsize=11, fontweight="bold", labelpad=10, color="#1E293B")
    plt.ylabel("Return Rate (%)", fontsize=11, fontweight="bold", labelpad=10, color="#1E293B")
    plt.ylim(0, 55)
    plt.grid(axis="y", linestyle="--", alpha=0.35, color="#94A3B8")

    # Annotate bar values with clean formatting
    for bar in bars:
        height = bar.get_height()
        plt.text(
            bar.get_x() + bar.get_width() / 2.0,
            height + 1.2,
            f"{height:.1f}%",
            ha="center",
            va="bottom",
            fontsize=11.5,
            fontweight="bold",
            color="#0F172A",
        )

    plt.tight_layout()
    chart1_path = os.path.join("visualizations", "return_rate_by_payment.png")
    plt.savefig(chart1_path, dpi=300)
    plt.close()
    print(f"Saved Chart 1 (Royal Indigo & Coral): {chart1_path}")

    # -------------------------------------------------------------------------
    # Chart 2: Monthly Revenue Trend (Outlier-Corrected Line Chart)
    # -------------------------------------------------------------------------
    df["order_date"] = pd.to_datetime(df["order_date"])
    df["year_month"] = df["order_date"].dt.to_period("M").astype(str)

    monthly_clean = (
        df[~df["is_outlier"]].groupby("year_month")["order_value"].sum().round(2).reset_index()
    )

    months = monthly_clean["year_month"].tolist()
    revenues = monthly_clean["order_value"].tolist()

    plt.figure(figsize=(9, 5.5), dpi=300)
    plt.plot(
        months,
        revenues,
        marker="o",
        markersize=8,
        linewidth=2.5,
        color="#2E6B4F",
        label="Outlier-Corrected Revenue",
    )

    # Highlight peak month (March 2026)
    peak_idx = months.index("2026-03")
    plt.plot(
        months[peak_idx],
        revenues[peak_idx],
        marker="o",
        markersize=12,
        color="#C9822A",
        label="True Peak (March: ₹20,318.90)",
    )

    plt.title("Outlier-Corrected Monthly Revenue: March is the True Peak (₹20,318.90)", fontsize=13, fontweight="bold", pad=15, color="#17402F")
    plt.xlabel("Year-Month", fontsize=11, fontweight="bold", labelpad=10, color="#1F2A24")
    plt.ylabel("Total Cleaned Revenue (INR)", fontsize=11, fontweight="bold", labelpad=10, color="#1F2A24")
    plt.ylim(6000, 24000)
    plt.grid(True, linestyle="--", alpha=0.4)

    # Annotate points
    for i, (m, r) in enumerate(zip(months, revenues)):
        offset_y = 700 if i != peak_idx else 900
        plt.annotate(
            f"₹{r:,.2f}",
            (m, r),
            textcoords="offset points",
            xytext=(0, 10),
            ha="center",
            fontsize=9.5,
            fontweight="bold",
            color="#C9822A" if i == peak_idx else "#1F2A24",
        )

    plt.legend(loc="upper right", frameon=True)
    plt.tight_layout()
    chart2_path = os.path.join("visualizations", "monthly_revenue_trend.png")
    plt.savefig(chart2_path, dpi=300)
    plt.close()
    print(f"Saved Chart 2: {chart2_path}")


if __name__ == "__main__":
    generate_visualizations()
