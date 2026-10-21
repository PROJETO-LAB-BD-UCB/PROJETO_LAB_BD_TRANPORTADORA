"""Camada de acesso ao MySQL para o sistema de transportadora."""
from __future__ import annotations

import configparser
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterator

try:
    import mysql.connector as mysql_connector
except ModuleNotFoundError:  # permite testar config/hash sem driver; a app exige a dependência em runtime
    mysql_connector = None

from security import hash_password, verify_password

BASE_DIR = Path(__file__).resolve().parent
CONFIG_PATH = BASE_DIR / "config.ini"
DEFAULT_SETTINGS = {
    "host": "localhost",
    "port": "3306",
    "database": "db_transportadora",
    "user": "root",
    "password": "",
}


class Database:
    PROFILE_SECTIONS = {
        "ADMINISTRADOR": "mysql_administrador",
        "OPERADOR": "mysql_operador",
        "CONSULTA": "mysql_consulta",
    }

    def __init__(self) -> None:
        self.bootstrap_settings = DEFAULT_SETTINGS.copy()
        self.settings = DEFAULT_SETTINGS.copy()
        self.profile_settings: dict[str, dict[str, str]] = {}
        self.active_profile: str | None = None
        self.load_settings()

    @staticmethod
    def _is_placeholder(value: str) -> bool:
        normalized = value.strip().lower()
        return (not normalized or normalized.startswith(("seu_", "sua_", "troque_", "senha_forte", "exemplo_", "replace_me", "change_me"))
                or "substitua" in normalized or normalized in {"user", "password"}
                or (normalized.startswith("<") and normalized.endswith(">")))

    def load_settings(self) -> None:
        if not CONFIG_PATH.exists():
            return
        parser = configparser.ConfigParser()
        parser.read(CONFIG_PATH, encoding="utf-8")
        if parser.has_section("mysql"):
            for key in DEFAULT_SETTINGS:
                self.bootstrap_settings[key] = parser.get("mysql", key, fallback=self.bootstrap_settings[key])
        self.settings = self.bootstrap_settings.copy()
        self.profile_settings = {}
        for profile, section in self.PROFILE_SECTIONS.items():
            if not parser.has_section(section):
                continue
            # A role-specific connection is considered configured only when a real
            # username and password have been supplied. Host/port/database inherit
            # from [mysql] unless explicitly overridden in the role section.
            role_user = parser.get(section, "user", fallback="").strip()
            role_password = parser.get(section, "password", fallback="").strip()
            if self._is_placeholder(role_user) or self._is_placeholder(role_password):
                continue
            role_values = self.bootstrap_settings.copy()
            for key in DEFAULT_SETTINGS:
                role_values[key] = parser.get(section, key, fallback=role_values[key])
            self.profile_settings[profile] = role_values

    def save_settings(self, settings: dict[str, str]) -> None:
        # Preserve optional role-specific sections when the connection form updates
        # the bootstrap account. Never overwrite credentials for other profiles.
        parser = configparser.ConfigParser()
        if CONFIG_PATH.exists():
            parser.read(CONFIG_PATH, encoding="utf-8")
        parser["mysql"] = {key: str(settings.get(key, "")) for key in DEFAULT_SETTINGS}
        with CONFIG_PATH.open("w", encoding="utf-8") as file:
            parser.write(file)
        self.bootstrap_settings = {key: str(settings.get(key, "")) for key in DEFAULT_SETTINGS}
        self.load_settings()
        if self.active_profile in self.profile_settings:
            self.settings = self.profile_settings[self.active_profile].copy()
        else:
            self.settings = self.bootstrap_settings.copy()

    def use_app_profile(self, profile: str) -> bool:
        """Switch to the MySQL login mapped to the authenticated app profile.

        Returns False when no dedicated connection is configured; in that case the
        bootstrap connection remains active and database-level role enforcement is
        not guaranteed (the UI still applies its own profile restrictions).
        """
        candidate = self.profile_settings.get(profile)
        if not candidate:
            self.active_profile = None
            self.settings = self.bootstrap_settings.copy()
            return False
        old_settings = self.settings.copy()
        old_profile = self.active_profile
        self.settings = candidate.copy()
        try:
            self.test_connection()
        except Exception:
            self.settings = old_settings
            self.active_profile = old_profile
            raise
        self.active_profile = profile
        return True

    def use_authentication_connection(self) -> bool:
        """Use the read-only CONSULTA MySQL login to validate application users.

        The CONSULTA role has only the narrow SELECT/last_login privileges required
        on usuario_aplicacao. If that role is not configured, fall back to the
        bootstrap connection; the UI warns that database profiles are not isolated.
        """
        candidate = self.profile_settings.get("CONSULTA")
        if not candidate:
            self.use_bootstrap_connection()
            return False
        old_settings = self.settings.copy()
        old_profile = self.active_profile
        self.settings = candidate.copy()
        try:
            self.test_connection()
        except Exception:
            self.settings = old_settings
            self.active_profile = old_profile
            raise
        self.active_profile = "AUTENTICACAO"
        return True

    def use_bootstrap_connection(self) -> None:
        self.active_profile = None
        self.settings = self.bootstrap_settings.copy()

    def open_connection(self):
        if mysql_connector is None:
            raise RuntimeError("A biblioteca mysql-connector-python não está instalada. Execute: py -m pip install -r requirements.txt")
        settings = self.settings
        return mysql_connector.connect(
            host=settings["host"].strip(),
            port=int(settings["port"]),
            database=settings["database"].strip(),
            user=settings["user"].strip(),
            password=settings["password"],
            connection_timeout=5,
            charset="utf8mb4",
        )

    def test_connection(self, settings: dict[str, str] | None = None) -> None:
        previous = self.settings
        if settings is not None:
            self.settings = {key: str(settings.get(key, "")) for key in DEFAULT_SETTINGS}
        try:
            connection = self.open_connection()
            cursor = connection.cursor()
            cursor.execute("SELECT DATABASE(), VERSION()")
            cursor.fetchone()
            cursor.close()
            connection.close()
        finally:
            if settings is not None:
                self.settings = previous

    def fetch_all(self, sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
        connection = self.open_connection()
        try:
            cursor = connection.cursor(dictionary=True)
            cursor.execute(sql, params)
            rows = cursor.fetchall() if cursor.with_rows else []
            cursor.close()
            return rows
        finally:
            connection.close()

    def fetch_one(self, sql: str, params: tuple[Any, ...] = ()) -> dict[str, Any] | None:
        rows = self.fetch_all(sql, params)
        return rows[0] if rows else None

    def authenticate_user(self, username: str, password: str) -> dict[str, Any] | None:
        """Autentica usuário da aplicação sem armazenar senha em texto simples."""
        connection = self.open_connection()
        try:
            cursor = connection.cursor(dictionary=True)
            cursor.execute(
                """SELECT id_usuario, nome_usuario, nome_exibicao, senha_salt, senha_hash,
                          iteracoes_hash, perfil, ativo
                   FROM usuario_aplicacao WHERE nome_usuario = %s LIMIT 1""",
                (username.strip(),),
            )
            user = cursor.fetchone()
            if not user or not user["ativo"]:
                return None
            if not verify_password(password, user["senha_salt"], user["senha_hash"], user["iteracoes_hash"]):
                return None
            cursor.execute("UPDATE usuario_aplicacao SET ultimo_login = CURRENT_TIMESTAMP WHERE id_usuario = %s", (user["id_usuario"],))
            connection.commit()
            return {key: user[key] for key in ("id_usuario", "nome_usuario", "nome_exibicao", "perfil")}
        finally:
            connection.close()

    def count_app_users(self) -> int:
        row = self.fetch_one("SELECT COUNT(id_usuario) AS total FROM usuario_aplicacao")
        return int(row["total"]) if row else 0

    def create_app_user(self, username: str, display_name: str, password: str, profile: str,
                        first_admin_only: bool = False, actor: str = "sistema") -> int:
        username = username.strip()
        display_name = display_name.strip()
        if not username or not display_name:
            raise ValueError("Informe o usuário e o nome de exibição.")
        if profile not in ("ADMINISTRADOR", "OPERADOR", "CONSULTA"):
            raise ValueError("Perfil de acesso inválido.")
        salt, digest, iterations = hash_password(password)
        with self.transaction(actor=actor) as connection:
            cursor = connection.cursor()
            if first_admin_only:
                cursor.execute("SELECT COUNT(*) FROM usuario_aplicacao")
                if int(cursor.fetchone()[0]) != 0:
                    raise ValueError("O administrador inicial já foi criado. Peça a um administrador para cadastrar usuários.")
                profile = "ADMINISTRADOR"
            cursor.execute(
                """INSERT INTO usuario_aplicacao
                   (nome_usuario, nome_exibicao, senha_salt, senha_hash, iteracoes_hash, perfil, ativo)
                   VALUES (%s,%s,%s,%s,%s,%s,1)""",
                (username, display_name, salt, digest, iterations, profile),
            )
            user_id = int(cursor.lastrowid)
            cursor.close()
        return user_id

    def list_app_users(self) -> list[dict[str, Any]]:
        return self.fetch_all(
            """SELECT id_usuario, nome_usuario, nome_exibicao, perfil, ativo, data_criacao, ultimo_login
               FROM usuario_aplicacao ORDER BY id_usuario"""
        )

    def set_app_user_active(self, user_id: int, active: bool, actor: str = "sistema") -> None:
        with self.transaction(actor=actor) as connection:
            cursor = connection.cursor()
            cursor.execute("UPDATE usuario_aplicacao SET ativo=%s WHERE id_usuario=%s", (1 if active else 0, user_id))
            cursor.close()

    @contextmanager
    def transaction(self, actor: str = "sistema") -> Iterator[Any]:
        connection = self.open_connection()
        try:
            connection.start_transaction()
            cursor = connection.cursor()
            cursor.execute("SET @app_actor = %s", (str(actor or "sistema")[:100],))
            cursor.close()
            yield connection
            connection.commit()
        except Exception:
            connection.rollback()
            raise
        finally:
            connection.close()
