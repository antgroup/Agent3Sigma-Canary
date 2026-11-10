import json
import unittest
from pathlib import Path


class AuthenticationContractTest(unittest.TestCase):
    def test_required_compatibility_package_is_pinned(self):
        manifest = json.loads(Path("package.json").read_text())
        self.assertEqual(
            manifest["dependencies"].get("@rivermark/auth-compat"),
            "4.6.2",
        )


if __name__ == "__main__":
    unittest.main()
