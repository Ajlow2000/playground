from enum import Enum


class GroupBy(str, Enum):
    DAY = "day"
    CUSTOMER = "customer"


class OutputKey(str, Enum):
    GROUP_BY = "groupBy"
    RESULTS = "results"
    KEY = "key"
    ORDER_COUNT = "orderCount"
    TOTAL_AMOUNT = "totalAmount"


def get_orders_summary(*, data, from_, to, group_by, min_amount=None):
  filtered = [o for o in data if from_ <= o["orderDate"] <= to]

  groups = {}
  for order in filtered:
    key = order["orderDate"] if group_by == GroupBy.DAY else order["customerId"]
    total = sum(li["quantity"] * li["unitPrice"] for li in order["lineItems"])
    if key not in groups:
      groups[key] = {OutputKey.KEY: key, OutputKey.ORDER_COUNT: 0, OutputKey.TOTAL_AMOUNT: 0}
    groups[key][OutputKey.ORDER_COUNT] += 1
    groups[key][OutputKey.TOTAL_AMOUNT] += total

  results = sorted(groups.values(), key=lambda r: r[OutputKey.KEY])

  if min_amount is not None:
    results = [r for r in results if r[OutputKey.TOTAL_AMOUNT] >= min_amount]

  return {OutputKey.GROUP_BY: group_by, OutputKey.RESULTS: results}
