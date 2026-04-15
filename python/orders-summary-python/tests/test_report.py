import json
from report import get_orders_summary


with open("tests/fixtures.json") as f:
    data = json.load(f)


def by_key(results):
    return {r["key"]: r for r in results}


def test_groups_by_day():
    out = get_orders_summary(
        data=data,
        from_="2026-01-10",
        to="2026-01-12",
        group_by="day"
    )

    assert out["groupBy"] == "day"
    assert [r["key"] for r in out["results"]] == [
        "2026-01-10",
        "2026-01-11",
        "2026-01-12"
    ]


def test_groups_by_customer():
    out = get_orders_summary(
        data=data,
        from_="2026-01-10",
        to="2026-01-12",
        group_by="customer"
    )

    assert out["groupBy"] == "customer"
    assert [r["key"] for r in out["results"]] == [
        "cust_1",
        "cust_2",
        "cust_3"
    ]
