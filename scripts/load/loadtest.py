"""Load test for the Malkkeum API. Stdlib only (asyncio + raw HTTP/1.1 keep-alive).

Usage:
  python scripts/load/loadtest.py --base http://127.0.0.1:8090 --concurrency 20 --duration 30

Prints requests, throughput, p50/p95/p99 latency (ms) and error rate. An error is a transport
failure or a 5xx. 4xx answers are counted separately: the mix sends some deliberately invalid
bodies, so they are expected and not a fault.
"""

import argparse
import asyncio
import random
import sys
import time
from urllib.parse import urlsplit

# (weight, method, path, body). Public reads dominate, as in the apps.
MIX = [
    (30, "GET", "/v1/services", None),
    (20, "GET", "/v1/content", None),
    (15, "GET", "/v1/slots?date=2030-01-07&district=11680", None),
    (10, "GET", "/v1/payments/methods", None),
    (10, "GET", "/health", None),
    (10, "POST", "/v1/quote/estimate", b"{}"),
    (5, "GET", "/v1/bookings", None),
]


def percentile(sorted_ms, pct):
    """Nearest-rank percentile of an ascending list; 0.0 for an empty list."""
    if not sorted_ms:
        return 0.0
    rank = max(1, -(-len(sorted_ms) * pct // 100))
    return sorted_ms[int(rank) - 1]


def pick(rng, mix):
    total = sum(w for w, *_ in mix)
    x = rng.uniform(0, total)
    for entry in mix:
        x -= entry[0]
        if x <= 0:
            return entry
    return mix[-1]


async def request(reader, writer, host, method, path, body, token):
    head = [f"{method} {path} HTTP/1.1", f"Host: {host}", "Connection: keep-alive"]
    if token:
        head.append(f"Authorization: Bearer {token}")
    if body is not None:
        head += ["Content-Type: application/json", f"Content-Length: {len(body)}"]
    writer.write(("\r\n".join(head) + "\r\n\r\n").encode() + (body or b""))
    await writer.drain()
    status_line = await reader.readline()
    if not status_line:
        raise ConnectionError("closed")
    status = int(status_line.split()[1])
    length = 0
    chunked = False
    while True:
        line = await reader.readline()
        if line in (b"\r\n", b""):
            break
        name, _, value = line.decode("latin-1").partition(":")
        if name.lower() == "content-length":
            length = int(value.strip())
        elif name.lower() == "transfer-encoding" and "chunked" in value.lower():
            chunked = True
    if chunked:
        while True:
            size = int((await reader.readline()).strip(), 16)
            await reader.readexactly(size + 2)
            if size == 0:
                break
    elif length:
        await reader.readexactly(length)
    return status


async def worker(args, deadline, results, rng, host):
    reader = writer = None
    while time.monotonic() < deadline:
        _, method, path, body = pick(rng, MIX)
        started = time.perf_counter()
        try:
            if writer is None:
                reader, writer = await asyncio.open_connection(host, args.port)
            status = await request(reader, writer, host, method, path, body, args.token)
            results.append((status, (time.perf_counter() - started) * 1000))
        except (OSError, ConnectionError, asyncio.IncompleteReadError, ValueError):
            results.append((0, (time.perf_counter() - started) * 1000))
            writer = None
    if writer is not None:
        writer.close()


async def run(args):
    url = urlsplit(args.base)
    args.port = url.port or (443 if url.scheme == "https" else 80)
    host = url.hostname
    rng = random.Random(args.seed)
    results = []
    deadline = time.monotonic() + args.duration
    started = time.monotonic()
    await asyncio.gather(*(worker(args, deadline, results, random.Random(rng.random()), host) for _ in range(args.concurrency)))
    return results, time.monotonic() - started


def report(results, elapsed):
    ok_ms = sorted(ms for status, ms in results if 200 <= status < 400)
    total = len(results)
    server_or_transport = sum(1 for status, _ in results if status == 0 or status >= 500)
    client = sum(1 for status, _ in results if 400 <= status < 500)
    lines = [
        f"requests      {total} in {elapsed:.1f}s ({total / elapsed if elapsed else 0:.1f} req/s)",
        f"2xx/3xx       {len(ok_ms)}",
        f"4xx (mix)     {client}",
        f"5xx/transport {server_or_transport}",
        f"error rate    {100 * server_or_transport / total if total else 0:.2f}% (5xx + transport)",
        f"latency ms    p50={percentile(ok_ms, 50):.1f} p95={percentile(ok_ms, 95):.1f} p99={percentile(ok_ms, 99):.1f}",
    ]
    print("\n".join(lines))
    return server_or_transport / total if total else 0.0


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--base", default="http://127.0.0.1:8080")
    p.add_argument("--concurrency", type=int, default=20)
    p.add_argument("--duration", type=float, default=30.0)
    p.add_argument("--token", default="", help="bearer token for the authenticated GET /v1/bookings share")
    p.add_argument("--seed", type=int, default=7)
    p.add_argument("--max-error-rate", type=float, default=0.01, help="exit 1 above this 5xx/transport rate")
    args = p.parse_args(argv)
    results, elapsed = asyncio.run(run(args))
    rate = report(results, elapsed)
    return 0 if rate <= args.max_error_rate else 1


if __name__ == "__main__":
    sys.exit(main())
