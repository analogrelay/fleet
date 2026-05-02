#!/usr/bin/env python3
import datetime
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from prometheus_client import CollectorRegistry, Gauge, generate_latest, CONTENT_TYPE_LATEST
import time

PORT = 10102

FLAT_RATE = 0.1270

TOU_ADJUSTMENTS = [
    {"hours": range(23, 24), "adjustment": -0.05},  # overnight pt1 (11pm-midnight)
    {"hours": range(0, 7),   "adjustment": -0.05},  # overnight pt2 (midnight-7am)
    {"hours": range(16, 21), "adjustment": +0.05},  # on-peak (4-9pm)
]

def current_rate():
    now = datetime.datetime.now()
    for period in TOU_ADJUSTMENTS:
        if now.hour in period["hours"]:
            return FLAT_RATE + period["adjustment"]
    return FLAT_RATE

registry = CollectorRegistry()
rate_gauge = Gauge('energy_rate_cad_per_kwh', 'Current TOU energy rate', registry=registry)

def poll():
    while True:
        rate_gauge.set(current_rate())
        time.sleep(60)

class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/metrics":
            output = generate_latest(registry)
            self.send_response(200)
            self.send_header("Content-Type", CONTENT_TYPE_LATEST)
            self.end_headers()
            self.wfile.write(output)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    threading.Thread(target=poll, daemon=True).start()
    HTTPServer(("127.0.0.1", PORT), MetricsHandler).serve_forever()
