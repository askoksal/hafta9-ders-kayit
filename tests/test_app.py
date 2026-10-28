from concurrent.futures import ThreadPoolExecutor

import pytest
from app import create_app

TOKEN = "test-only-" + "a" * 40


@pytest.fixture
def app():
    return create_app({"TESTING": True, "API_TOKEN": TOKEN, "SOURCE_COMMIT": "test-commit"})


@pytest.fixture
def client(app):
    return app.test_client()


def send(client, student="DEMO001", course="BULUT101", token=TOKEN):
    return client.post('/api/enrollments', json={"student_id": student, "course_id": course},
                       headers={"Authorization": "Bearer " + token})


def test_missing_token_fails_closed(monkeypatch):
    monkeypatch.delenv('API_TOKEN', raising=False)
    with pytest.raises(RuntimeError):
        create_app()


def test_catalog_and_version(client):
    assert client.get('/api/courses').json['courses'][0]['capacity'] == 2
    assert client.get('/version').json == {"version": "1.0.0", "commit": "test-commit"}


@pytest.mark.parametrize('path', ['/', '/healthz', '/readyz', '/static/app.js', '/static/style.css'])
def test_public_endpoints(client, path):
    assert client.get(path).status_code == 200


def test_create_and_duplicate(client):
    assert send(client).status_code == 201
    assert send(client).status_code == 409
    assert client.get('/api/courses').json['courses'][0]['enrolled'] == 1


def test_capacity_boundary(client):
    assert send(client, 'DEMO001').status_code == 201
    assert send(client, 'DEMO002').status_code == 201
    assert send(client, 'DEMO003').status_code == 409


@pytest.mark.parametrize('student', ['001', '', '<script>', None, 123, 'DEMO0001'])
def test_invalid_student(client, student):
    assert send(client, student).status_code == 400


def test_unknown_course(client):
    assert send(client, course='UNKNOWN').status_code == 404


def test_unauthorized_and_no_token_disclosure(client):
    assert send(client, token='wrong').status_code == 401
    assert client.get('/api/enrollments').status_code == 401
    assert TOKEN not in client.get('/').text
    assert TOKEN not in client.get('/version').text


def test_payload_errors(client):
    headers = {"Authorization": "Bearer " + TOKEN}
    assert client.post('/api/enrollments', data='x', headers=headers).status_code == 415
    assert client.post('/api/enrollments', json=[], headers=headers).status_code == 400
    assert client.post('/api/enrollments', json={"student_id": "DEMO001"}, headers=headers).status_code == 400
    assert client.post('/api/enrollments', data='{', content_type='application/json', headers=headers).status_code == 400
    assert client.post('/api/enrollments', data='x'*5000, content_type='application/json', headers=headers).status_code == 413


def test_security_headers_and_html_escaping():
    app = create_app({"TESTING": True, "API_TOKEN": TOKEN, "COURSE_BANNER": '<script>alert(1)</script>'})
    response = app.test_client().get('/')
    assert '&lt;script&gt;' in response.text
    assert "script-src 'self'" in response.headers['Content-Security-Policy']
    assert response.headers['Cache-Control'] == 'no-store'


def test_instances_do_not_share_state(client):
    assert send(client).status_code == 201
    fresh = create_app({"TESTING": True, "API_TOKEN": TOKEN}).test_client()
    assert fresh.get('/api/courses').json['courses'][0]['enrolled'] == 0


def test_concurrent_capacity(app):
    def attempt(n):
        with app.test_client() as c:
            return send(c, f'DEMO{n:03}').status_code
    with ThreadPoolExecutor(max_workers=8) as executor:
        codes = list(executor.map(attempt, range(10)))
    assert codes.count(201) == 2
    assert codes.count(409) == 8
