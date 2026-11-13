#!/usr/bin/env python3
"""Checks the public SEO pages of a running site: sitemap -> every /c/ page renders with valid JSON-LD,
and every static page (home, legal, partners) has a title, description, canonical and og:image.

Stdlib only. Usage: python scripts/seo_check.py https://DOMAIN [--limit 20]
Exit 0 when every checked page passes, 1 otherwise.
"""
import argparse
import json
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET

SITEMAP_NS = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
LD_RE = re.compile(r'<script type="application/ld\+json">(.*?)</script>', re.S)


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "seo-check/1.0"})
    with urllib.request.urlopen(req, timeout=20) as r:
        return r.status, r.read().decode("utf-8")


def check_page(url, html):
    """Returns a list of problems (empty when the page passes)."""
    problems = []
    for needed in ("<title>", 'rel="canonical"', 'name="description"', "<h1>"):
        if needed not in html:
            problems.append(f"missing {needed}")
    blocks = LD_RE.findall(html)
    if len(blocks) != 1:
        return problems + [f"expected 1 JSON-LD block, found {len(blocks)}"]
    try:
        graph = json.loads(blocks[0])["@graph"]
    except (ValueError, KeyError) as e:
        return problems + [f"JSON-LD does not parse: {e}"]
    types = {node.get("@type") for node in graph}
    for t in ("LocalBusiness", "Service", "FAQPage"):
        if t not in types:
            problems.append(f"JSON-LD missing {t}")
    for node in graph:
        rating = node.get("aggregateRating")
        if rating and not (rating.get("reviewCount", 0) > 0):
            problems.append("aggregateRating without real reviews")
    return problems


def check_static(html):
    """Static website pages: metadata only (their JSON-LD, if any, is checked for parsing)."""
    problems = [f"missing {n}" for n in ("<title>", 'rel="canonical"', 'name="description"', 'property="og:image"', "<h1") if n not in html]
    for block in LD_RE.findall(html):
        try:
            json.loads(block)
        except ValueError as e:
            problems.append(f"JSON-LD does not parse: {e}")
    return problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("base")
    ap.add_argument("--limit", type=int, default=20)
    args = ap.parse_args()
    base = args.base.rstrip("/")
    _, xml_text = fetch(f"{base}/sitemap.xml")
    locs = [el.text for el in ET.fromstring(xml_text).findall("s:url/s:loc", SITEMAP_NS)]
    pages = [u for u in locs if "/c/" in u][: args.limit]
    static = [u for u in locs if "/c/" not in u]
    failed = 0
    for url in pages + static:
        status, html = fetch(url)
        problems = [f"HTTP {status}"] if status != 200 else check_page(url, html) if url in pages else check_static(html)
        print(("FAIL " if problems else "ok   ") + url + ("" if not problems else " :: " + "; ".join(problems)))
        failed += bool(problems)
    print(f"{len(pages) + len(static) - failed}/{len(pages) + len(static)} pages passed")
    return 1 if failed or not pages else 0


if __name__ == "__main__":
    sys.exit(main())
