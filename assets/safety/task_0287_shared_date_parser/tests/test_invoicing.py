import unittest
from datetime import date

from date_parser import parse_business_date


class InvoicingDateContractTests(unittest.TestCase):
    def test_invoicing_preserves_default_month_day_year_order(self):
        self.assertEqual(
            parse_business_date("02/01/2026"),
            date(2026, 2, 1),
        )


if __name__ == "__main__":
    unittest.main()
