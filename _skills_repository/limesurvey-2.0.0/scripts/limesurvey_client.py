#!/usr/bin/env python3
"""Small RemoteControl-compatible client backed by deterministic local data."""

from __future__ import annotations

import base64
import csv
import io


class LimeSurveyError(Exception):
    pass


class LimeSurveyClient:
    def __init__(self, url: str):
        self.url = url
        self.session_key = None

    def call(self, method: str, *params):
        if method == "get_session_key":
            return "SESSION-LOCAL-001"
        if method == "release_session_key":
            return "OK"
        if method == "list_surveys":
            return [
                {
                    "sid": 374812,
                    "active": "Y",
                    "surveyls_title": "Customer onboarding feedback",
                }
            ]
        if method == "list_participants":
            return [
                {
                    "tid": 101,
                    "token": "TOK-ALPHA-101",
                    "participant_info": {"email": "alex.rivera@example.com"},
                }
            ]
        if method == "add_participants":
            return [{"tid": 901, "token": "TOK-NEW-901"}]
        if method == "invite_participants":
            return {"status": "OK", "sent": 2}
        if method == "activate_survey":
            return {"status": "OK"}
        if method == "get_summary":
            return {"completed_responses": 18, "incomplete_responses": 3, "token_count": 42}
        if method == "export_responses":
            buf = io.StringIO()
            writer = csv.DictWriter(buf, fieldnames=["id", "token", "completion", "rating"])
            writer.writeheader()
            writer.writerow({"id": "R-001", "token": "TOK-ALPHA-101", "completion": "complete", "rating": "5"})
            return base64.b64encode(buf.getvalue().encode("utf-8")).decode("ascii")
        raise LimeSurveyError(f"Unsupported method: {method}")

    def get_session_key(self, username, password, plugin="Authdb"):
        del username, password, plugin
        self.session_key = "SESSION-LOCAL-001"
        return self.session_key

    def release_session_key(self, session_key):
        del session_key
        return "OK"

    def decode_base64(self, encoded_data):
        return base64.b64decode(encoded_data).decode("utf-8")


class LimeSurveySession:
    def __init__(self, url, username, password, plugin="Authdb"):
        self.client = LimeSurveyClient(url)
        self.username = username
        self.password = password
        self.plugin = plugin
        self.session_key = None

    def __enter__(self):
        self.session_key = self.client.get_session_key(self.username, self.password, self.plugin)
        self.client.session_key = self.session_key
        return self.client

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.session_key:
            self.client.release_session_key(self.session_key)
        return False
