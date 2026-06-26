# discourse-turnstile

Cloudflare Turnstile captcha on the Discourse **signup form**, with real
server-side verification.

This is a fork of the official
[discourse-hcaptcha](https://github.com/discourse/discourse-hcaptcha) plugin
(MIT). The architecture is unchanged — only the captcha provider was swapped
from hCaptcha to Cloudflare Turnstile:

| | hCaptcha (original) | Turnstile (this fork) |
|---|---|---|
| Client script | `hcaptcha.com/1/api.js` | `challenges.cloudflare.com/turnstile/v0/api.js` |
| Server siteverify | `hcaptcha.com/siteverify` | `challenges.cloudflare.com/turnstile/v0/siteverify` |
| Settings | `hcaptcha_site_key` / `hcaptcha_secret_key` | `turnstile_site_key` / `turnstile_secret_key` |
| Enable flag | `discourse_hcaptcha_enabled` | `discourse_turnstile_enabled` |

The token round-trip (client POSTs the token to `/turnstile/create.json`,
server stashes it in Redis keyed by an encrypted cookie, then validates it in a
`before_action` on `UsersController#create`) is identical to the original, so
verification failure **blocks account creation** — this is not a cosmetic
widget.

## Install

1. Create a Turnstile widget in the Cloudflare dashboard (Turnstile → Add
   widget), hostname = your forum domain, mode = Managed. Copy the **Site Key**
   and **Secret Key**.
2. Add this plugin to `containers/app.yml` under `hooks: after_code`:

   ```yaml
   hooks:
     after_code:
       - exec:
           cd: $home/plugins
           cmd:
             - git clone https://github.com/tuntun1337/discourse-turnstile.git
   ```
3. Rebuild: `cd /var/discourse && ./launcher rebuild app`
4. Admin → Settings → search `turnstile`: tick `discourse turnstile enabled`,
   paste `turnstile site key` and `turnstile secret key`. Local logins must be
   enabled. The widget appears on the local signup form.

## Notes

- Only the local signup form is protected (not login, SSO/OAuth, or invites) —
  same scope as the original hCaptcha plugin.
- It does not send `remoteip` to siteverify (neither did the original). If you
  add it, make sure your reverse-proxy chain restores the real visitor IP
  (`CF-Connecting-IP` / `set_real_ip_from`) first.

## License

MIT — see [LICENSE](LICENSE). Retains the original CDCK copyright notice.
