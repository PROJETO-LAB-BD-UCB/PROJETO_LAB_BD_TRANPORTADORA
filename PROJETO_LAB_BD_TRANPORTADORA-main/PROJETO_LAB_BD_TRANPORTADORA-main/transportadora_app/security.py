"""Funções de autenticação com hash PBKDF2-HMAC-SHA256 e sal aleatório."""
from __future__ import annotations

import hashlib
import hmac
import secrets

ITERATIONS = 310_000


def hash_password(password: str) -> tuple[str, str, int]:
    if len(password) < 10:
        raise ValueError("A senha deve ter pelo menos 10 caracteres.")
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, ITERATIONS)
    return salt.hex(), digest.hex(), ITERATIONS


def verify_password(password: str, salt_hex: str, expected_hash: str, iterations: int = ITERATIONS) -> bool:
    try:
        salt = bytes.fromhex(salt_hex)
    except (TypeError, ValueError):
        return False
    candidate = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, int(iterations)).hex()
    return hmac.compare_digest(candidate, str(expected_hash))
