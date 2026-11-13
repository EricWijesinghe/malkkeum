# Security policy

## Reporting a vulnerability

Please report security issues **privately** through GitHub:
**Security → Report a vulnerability** on this repository
([private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)).
Do not open a public issue, pull request or discussion for a suspected vulnerability.

Include what you can of:

- the affected component (API, installer, website, customer / partner app, console) and version or commit;
- steps to reproduce or a proof of concept;
- the impact you expect (data exposure, payment manipulation, account takeover, ...).

We acknowledge reports within 3 business days and aim to ship a fix for confirmed high-severity
issues within 14 days. We credit reporters in the advisory unless you ask us not to.

## Supported versions

Only the latest release on the `stable` channel and the current `beta` receive security fixes.
Installed servers pick up fixes through the weekly automatic update or `sudo dahae update`.

## Scope

In scope: this repository's code, the installer and the published container images.
Out of scope: third-party services (PortOne, Toss Payments, Kakao, Naver, Google, Apple, Solapi,
Anthropic) and issues that need a compromised server or device.

Please do not run automated scanners against production servers, access other users' data, or
degrade service while testing.
