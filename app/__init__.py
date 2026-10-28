"""Hafta 9: tek süreçli ve geçici verili ders kayıt hizmeti."""
import hmac
import os
import re
from threading import Lock

from flask import Flask, jsonify, render_template, request
from werkzeug.exceptions import HTTPException

COURSES = (
    {"id": "BULUT101", "name": "Bulut Bilişim", "capacity": 2},
    {"id": "YAZ102", "name": "Yazılım Mühendisliği", "capacity": 3},
)


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.update(
        MAX_CONTENT_LENGTH=4096,
        API_TOKEN=os.environ.get("API_TOKEN", ""),
        APP_VERSION=os.environ.get("APP_VERSION", "1.0.0"),
        SOURCE_COMMIT=os.environ.get("SOURCE_COMMIT", "local"),
        COURSE_BANNER=os.environ.get("COURSE_BANNER", "Hafta 9 Ders Kayıt Hizmeti"),
    )
    if test_config:
        app.config.update(test_config)
    if len(app.config["API_TOKEN"]) < 32:
        raise RuntimeError("API_TOKEN en az 32 karakter olmalıdır; kaynak koda yazmayın.")
    # Tek gunicorn işçisi ve kilitli erişim. Çok Pod arasında paylaşılmaz.
    enrollments = set()
    lock = Lock()

    def authorized():
        supplied = request.headers.get("Authorization", "")
        expected = "Bearer " + app.config["API_TOKEN"]
        return hmac.compare_digest(supplied.encode(), expected.encode())

    @app.after_request
    def headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; script-src 'self'; style-src 'self'; "
            "connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"
        )
        return response

    @app.errorhandler(HTTPException)
    def http_error(error):
        return jsonify(error=error.name), error.code

    @app.get("/")
    def index():
        return render_template("index.html", banner=app.config["COURSE_BANNER"])

    @app.get("/healthz")
    @app.get("/readyz")
    def health():
        return jsonify(status="ok")

    @app.get("/version")
    def version():
        return jsonify(version=app.config["APP_VERSION"], commit=app.config["SOURCE_COMMIT"])

    @app.get("/api/courses")
    def courses():
        with lock:
            result = [dict(c, enrolled=sum(cid == c["id"] for _, cid in enrollments)) for c in COURSES]
        return jsonify(courses=result)

    @app.route("/api/enrollments", methods=["GET", "POST"])
    def registration():
        if not authorized():
            return jsonify(error="Erişim belirteci geçersiz."), 401
        if request.method == "GET":
            with lock:
                rows = [{"student_id": s, "course_id": c} for s, c in sorted(enrollments)]
            return jsonify(enrollments=rows)
        if not request.is_json:
            return jsonify(error="application/json gereklidir."), 415
        data = request.get_json()
        if not isinstance(data, dict) or set(data) != {"student_id", "course_id"}:
            return jsonify(error="Yalnız student_id ve course_id alanları gereklidir."), 400
        student, course_id = data["student_id"], data["course_id"]
        if not isinstance(student, str) or not re.fullmatch(r"DEMO[0-9]{3}", student):
            return jsonify(error="Öğrenci kimliği DEMO001 biçiminde olmalıdır."), 400
        course = next((c for c in COURSES if c["id"] == course_id), None)
        if course is None:
            return jsonify(error="Ders bulunamadı."), 404
        with lock:
            if (student, course_id) in enrollments:
                return jsonify(error="Bu ders için kayıt zaten var."), 409
            if sum(cid == course_id for _, cid in enrollments) >= course["capacity"]:
                return jsonify(error="Ders kontenjanı dolu."), 409
            enrollments.add((student, course_id))
        return jsonify(student_id=student, course_id=course_id), 201

    return app
