import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import InputTip from "discourse/components/input-tip";
import loadScript from "discourse/lib/load-script";
import { i18n } from "discourse-i18n";

const TURNSTILE_SCRIPT_URL =
  "https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit";

export default class Turnstile extends Component {
  @service turnstileService;

  @tracked widgetId;
  @tracked turnstileConfigError = "";
  turnstile;

  constructor() {
    super(...arguments);
    this.initializeTurnstile(this.args.siteKey);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    if (this.isTurnstileLoaded() && this.widgetId) {
      this.turnstile.remove(this.widgetId);
    }
  }

  initializeTurnstile(siteKey) {
    if (this.isTurnstileLoaded()) {
      next(() => {
        if (document.getElementById("turnstile-field")) {
          this.renderTurnstile(siteKey);
        }
      });
      return;
    }

    this.loadTurnstileScript(siteKey);
  }

  isTurnstileLoaded() {
    return typeof this.turnstile !== "undefined";
  }

  async loadTurnstileScript(siteKey) {
    // loadScript injects api.js with async and resolves on its load event, so
    // window.turnstile is ready here. Do NOT use turnstile.ready() — it throws
    // when api.js was loaded with async/defer; just render directly.
    await loadScript(TURNSTILE_SCRIPT_URL);
    this.turnstile = window.turnstile;
    this.renderTurnstile(siteKey);
  }

  renderTurnstile(siteKey) {
    if (!this.isTurnstileLoaded() || !this.args.siteKey) {
      this.turnstileConfigError = i18n(
        "discourse_turnstile.contact_system_administrator"
      );
      return;
    }

    this.widgetId = this.turnstile.render("#turnstile-field", {
      sitekey: siteKey,
      callback: (token) => {
        this.turnstileService.token = token;
        this.turnstileService.invalid = !token;
      },
      "expired-callback": () => {
        this.turnstileService.invalid = true;
      },
      "error-callback": () => {
        this.turnstileService.invalid = true;
      },
    });

    this.turnstileService.registerWidget(this.turnstile, this.widgetId);
  }

  <template>
    <div id="turnstile-field" class="cf-turnstile"></div>

    {{#if this.turnstileConfigError}}
      <div class="alert alert-error">
        {{this.turnstileConfigError}}
      </div>
    {{/if}}

    {{#if this.turnstileService.submitFailed}}
      <InputTip @validation={{this.turnstileService.inputValidation}} />
    {{/if}}
  </template>
}
