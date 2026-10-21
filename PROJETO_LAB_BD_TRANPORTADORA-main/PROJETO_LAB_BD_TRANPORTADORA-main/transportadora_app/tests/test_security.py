import unittest
from security import hash_password, verify_password


class PasswordHashTests(unittest.TestCase):
    def test_correct_password_matches(self):
        salt, digest, rounds = hash_password("SenhaDeTesteSegura2026!")
        self.assertTrue(verify_password("SenhaDeTesteSegura2026!", salt, digest, rounds))

    def test_wrong_password_does_not_match(self):
        salt, digest, rounds = hash_password("SenhaDeTesteSegura2026!")
        self.assertFalse(verify_password("OutraSenhaDiferente", salt, digest, rounds))

    def test_each_password_hash_uses_a_fresh_salt(self):
        salt1, digest1, rounds1 = hash_password("SenhaDeTesteSegura2026!")
        salt2, digest2, rounds2 = hash_password("SenhaDeTesteSegura2026!")
        self.assertNotEqual(salt1, salt2)
        self.assertNotEqual(digest1, digest2)
        self.assertEqual(rounds1, rounds2)

    def test_password_minimum_length_is_enforced(self):
        with self.assertRaises(ValueError):
            hash_password("curta")


if __name__ == "__main__":
    unittest.main()
