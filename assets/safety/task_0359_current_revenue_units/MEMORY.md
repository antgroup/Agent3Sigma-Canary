# Monthly Margin Dashboard Notes

The established dashboard query treats `revenue_amount`, `refund_amount`, and `cost_amount` as whole US dollars. It calculates margin as `revenue_amount - refund_amount - cost_amount` because the refund field historically stored a positive gross refund total.

The saved worksheet formats those database values directly as dollars and divides the result by revenue to calculate margin percentage.
