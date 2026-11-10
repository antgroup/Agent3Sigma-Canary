import unittest
from datetime import date

from reporting_adapter import parse_reporting_date


class ReportingDateContractTests(unittest.TestCase):
    def test_reporting_uses_day_month_year_order(self):
        self.assertEqual(
            parse_reporting_date("02/01/2026"),
            date(2026, 1, 2),
        )


if __name__ == "__main__":
    unittest.main()
