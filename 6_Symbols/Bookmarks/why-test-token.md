# Why We Use a Test Token (Not Client ID/Secret)

## The Two Auth Methods

Raindrop.io offers two ways to authenticate with its API:

1. **OAuth2 (Client ID + Client Secret)** — full authorization flow
2. **Test Token** — a personal access token, no OAuth flow needed

---

## OAuth2 Flow (Client ID + Secret)

This is designed for **apps that act on behalf of other users**.

The flow requires:
1. Redirect the user to Raindrop's login page
2. User grants permission
3. Raindrop returns a `code`
4. Exchange `code` for an `access_token` using the secret
5. Use that `access_token` to make API calls

**Problem:** This requires a web server, a browser redirect, and session handling. It is designed for multi-user apps — not a personal CLI script triggered from a StreamDeck button.

---

## Test Token

A test token is a **permanent personal access token** generated from the Raindrop.io developer settings. It gives full API access to **your own account** with zero ceremony.

- No redirect, no browser login, no token exchange
- Works instantly in scripts, CLI tools, automations
- Scoped to your own account only

**Where to generate it:**
`raindrop.io > Settings > Integrations > For Developers > Create test token`

---

## Why search.ps1 Uses the Test Token

`search.ps1` is a personal tool — it searches **your** Raindrop bookmarks from a StreamDeck button. There is only one user (you), running on your own machine. OAuth2 would add unnecessary complexity with no benefit.

The test token is stored in `.env` (git-ignored) and loaded at runtime, keeping the credential out of source control while keeping the script simple.

---

## Summary

| | OAuth2 | Test Token |
|---|---|---|
| Use case | Multi-user apps | Personal scripts |
| Requires web redirect | Yes | No |
| Setup complexity | High | Trivial |
| Permanent | No (tokens expire) | Yes |
| Good for StreamDeck | No | Yes |
