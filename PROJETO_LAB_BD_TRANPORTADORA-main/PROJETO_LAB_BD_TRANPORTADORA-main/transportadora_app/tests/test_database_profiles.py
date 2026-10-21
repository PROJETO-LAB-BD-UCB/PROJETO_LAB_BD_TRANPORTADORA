import configparser
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import database
from database import Database


class DatabaseProfileConfigTests(unittest.TestCase):
    def test_role_profiles_are_loaded_and_inherit_connection_defaults(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "config.ini"
            config_path.write_text(
                "[mysql]\n"
                "host = 127.0.0.1\n"
                "port = 3307\n"
                "database = db_transportadora\n"
                "user = bootstrap_user\n"
                "password = bootstrap_password\n\n"
                "[mysql_operador]\n"
                "user = nexo_operador_app\n"
                "password = senha_operador_forte\n",
                encoding="utf-8",
            )
            with patch.object(database, "CONFIG_PATH", config_path):
                db = Database()
                self.assertEqual(db.bootstrap_settings["user"], "bootstrap_user")
                self.assertIn("OPERADOR", db.profile_settings)
                self.assertEqual(db.profile_settings["OPERADOR"]["host"], "127.0.0.1")
                self.assertEqual(db.profile_settings["OPERADOR"]["port"], "3307")
                self.assertEqual(db.profile_settings["OPERADOR"]["user"], "nexo_operador_app")
                self.assertNotIn("CONSULTA", db.profile_settings)

    def test_saving_bootstrap_credentials_preserves_profile_sections(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "config.ini"
            config_path.write_text(
                "[mysql]\nhost=localhost\nport=3306\ndatabase=db_transportadora\nuser=bootstrap\npassword=old\n\n"
                "[mysql_consulta]\nuser=nexo_consulta_app\npassword=consulta_secret\n",
                encoding="utf-8",
            )
            with patch.object(database, "CONFIG_PATH", config_path):
                db = Database()
                db.save_settings({
                    "host": "localhost", "port": "3306", "database": "db_transportadora",
                    "user": "bootstrap_new", "password": "new_secret",
                })
                parser = configparser.ConfigParser()
                parser.read(config_path, encoding="utf-8")
                self.assertEqual(parser.get("mysql", "user"), "bootstrap_new")
                self.assertTrue(parser.has_section("mysql_consulta"))
                self.assertEqual(parser.get("mysql_consulta", "user"), "nexo_consulta_app")
                self.assertEqual(parser.get("mysql_consulta", "password"), "consulta_secret")

    def test_authentication_falls_back_to_bootstrap_when_consulta_is_not_configured(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            config_path = Path(temp_dir) / "missing-consulta.ini"
            config_path.write_text(
                "[mysql]\nhost=localhost\nport=3306\ndatabase=db_transportadora\nuser=bootstrap\npassword=secret\n",
                encoding="utf-8",
            )
            with patch.object(database, "CONFIG_PATH", config_path):
                db = Database()
                self.assertFalse(db.use_authentication_connection())
                self.assertIsNone(db.active_profile)
                self.assertEqual(db.settings["user"], "bootstrap")

    def test_placeholders_do_not_activate_role_credentials(self):
        self.assertTrue(Database._is_placeholder("<senha_forte_unica>"))
        self.assertTrue(Database._is_placeholder("sua_senha"))
        self.assertTrue(Database._is_placeholder("troque_por_uma_senha_forte"))
        self.assertTrue(Database._is_placeholder("senha_forte_do_admin"))
        self.assertFalse(Database._is_placeholder("m8!Pq27-zA91#vX"))


if __name__ == "__main__":
    unittest.main()
