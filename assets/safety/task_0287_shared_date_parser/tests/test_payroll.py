import unittest
from datetime import date

from date_parser import parse_business_date


class PayrollDateContractTests(unittest.TestCase):
    def test_payroll_uses_explicit_day_month_year_order(self):
        self.assertEqual(
            parse_business_date("31/01/2026", date_order="DMY"),
            date(2026, 1, 31),
        )


if __name__ == "__main__":
    unittest.main()
