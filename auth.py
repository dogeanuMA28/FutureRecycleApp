"""Local accounts and an in-memory session for the desktop demo."""

import hashlib
import hmac
import re
import secrets
import sqlite3

from PySide6.QtCore import QObject, Property, Signal, Slot


class Session(QObject):
    changed = Signal()

    def __init__(self, database_file, parent=None):
        super().__init__(parent)
        database_file.parent.mkdir(parents=True, exist_ok=True)
        self._db = sqlite3.connect(database_file)
        self._db.execute(
            "CREATE TABLE IF NOT EXISTS accounts "
            "(username TEXT PRIMARY KEY, salt BLOB NOT NULL, digest BLOB NOT NULL)"
        )
        self._username = ""

    @Property(str, notify=changed)
    def username(self):
        return self._username

    @Property(bool, notify=changed)
    def needsSetup(self):
        return self._db.execute("SELECT 1 FROM accounts LIMIT 1").fetchone() is None

    @staticmethod
    def _digest(password, salt):
        return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000)

    @Slot(str, str, str, result=str)
    def createAccount(self, username, password, confirmation):
        username = username.strip().lower()
        if not re.fullmatch(r"[a-z0-9._-]{3,32}", username):
            return "Use 3–32 letters, digits, dots, underscores or hyphens."
        if not password:
            return "Enter a password."
        if password != confirmation:
            return "Passwords do not match."

        salt = secrets.token_bytes(16)
        values = (username, salt, self._digest(password, salt))
        try:
            with self._db:
                if self._username:
                    self._db.execute("INSERT INTO accounts VALUES (?, ?, ?)", values)
                else:
                    result = self._db.execute(
                        "INSERT INTO accounts SELECT ?, ?, ? "
                        "WHERE NOT EXISTS (SELECT 1 FROM accounts)", values
                    )
                    if result.rowcount != 1:
                        self.changed.emit()
                        return "Sign in to add another account."
        except sqlite3.IntegrityError:
            return "That username is already in use."
        except sqlite3.Error:
            return "Could not save the account. Try again."

        if not self._username:
            self._username = username
            self.changed.emit()
        return ""

    @Slot(str, str, result=str)
    def signIn(self, username, password):
        if self._username:
            return ""
        username = username.strip().lower()
        try:
            account = self._db.execute(
                "SELECT salt, digest FROM accounts WHERE username = ?", (username,)
            ).fetchone()
        except sqlite3.Error:
            return "Could not read the accounts. Try again."
        salt, digest = account or (bytes(16), bytes(32))
        if hmac.compare_digest(self._digest(password, salt), digest) and account:
            self._username = username
            self.changed.emit()
            return ""
        return "Incorrect username or password."

    @Slot()
    def signOut(self):
        if self._username:
            self._username = ""
            self.changed.emit()

    def close(self):
        self._db.close()
