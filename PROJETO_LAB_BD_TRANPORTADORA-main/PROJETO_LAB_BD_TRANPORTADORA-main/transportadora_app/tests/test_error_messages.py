import unittest
from types import SimpleNamespace

from app import TransportadoraApp


class FriendlyDatabaseMessageTests(unittest.TestCase):
    def test_business_trigger_error_is_friendly(self):
        exc = SimpleNamespace(errno=1644, msg="ERROR 1644 (45000): internal trigger message")
        msg = TransportadoraApp._friendly_db_message(exc)
        self.assertIn("regra de negócio", msg)
        self.assertNotIn("internal trigger message", msg)

    def test_constraint_error_is_friendly(self):
        exc = SimpleNamespace(errno=3819, msg="Check constraint failed")
        msg = TransportadoraApp._friendly_db_message(exc)
        self.assertIn("integridade do banco", msg)

    def test_unexpected_driver_exception_is_not_shown_raw(self):
        exc = SimpleNamespace(errno=9999, msg="raw server internals")
        msg = TransportadoraApp._friendly_db_message(exc)
        self.assertIn("erro inesperado do banco", msg)
        self.assertNotIn("raw server internals", msg)


if __name__ == "__main__":
    unittest.main()
