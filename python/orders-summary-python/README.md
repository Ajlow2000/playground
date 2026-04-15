# Orders Summary (Python)

This project implements a function that generates a summary of orders grouped by either day or customer.

## Overview

You will implement a function that processes order data and returns aggregated metrics grouped by either day or customer.

## Function to Implement

`get_orders_summary(data, from_, to, group_by, min_amount=None)`

This function is located in `report.py`.

Your goal is to implement this function so that all tests pass.

## Parameters

- `data`: list of orders  
- `from_`: start date (YYYY-MM-DD, inclusive)  
- `to`: end date (YYYY-MM-DD, inclusive)  
- `group_by`: `"day"` or `"customer"`  
- `min_amount` (optional): minimum computed order amount  

## Requirements

- Date filtering applies to `orderDate` (inclusive)  
- Order amount = sum(quantity * unitPrice) across all line items  
- Results can be grouped by:
  - `"day"` → `orderDate`  
  - `"customer"` → `customerId`  

Each group must include:

- `key`  
- `count`  
- `totalAmount`  
- `avgAmount`  

If `min_amount` is provided, only include orders with computed amount greater than or equal to that value.

Results must be sorted by `key` ascending.

## Setup

**Install uv** (if not already installed)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh  # Mac/Linux
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"  # Windows
```

**Clone and run tests**

```bash
git clone https://github.com/JayDi11a/orders-summary-python.git
cd orders-summary-python
uv run pytest
```

## Important Notes

- Tests may fail initially — this is expected  
- Your task is to implement the function so that all tests pass  
- You should only modify `report.py`  

## Do Not

- Do not modify test files  
- Do not move or copy files into the `tests/` directory  
- Do not rename files or change the project structure  
- Do not add configuration files (for example, `conftest.py`) to fix imports  

If you are editing anything outside `report.py`, you are likely going in the wrong direction.

## Project Structure

    orders-summary-python
    │
    ├── report.py
    ├── pyproject.toml
    ├── README.md
    │
    └── tests
        ├── fixtures.json
        └── test_report.py

## Data

Test data is located in:

    tests/fixtures.json

