import { Promise } from "rsvp";
import { ajax } from "discourse/lib/ajax";
import { getOwnerWithFallback } from "discourse/lib/get-owner";
import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "discourse-turnstile";

function initializeTurnstile(api, container) {
  const siteSettings = container.lookup("service:site-settings");

  if (!siteSettings.discourse_turnstile_enabled) {
    return;
  }

  api.modifyClassStatic("model:user", {
    pluginId: PLUGIN_ID,

    createAccount() {
      const turnstileService = getOwnerWithFallback(this).lookup(
        "service:turnstile-service"
      );
      turnstileService.submitted = true;

      if (turnstileService.invalid) {
        return Promise.reject();
      }

      const data = {
        token: turnstileService.token,
      };

      const originalAccountCreation = this._super;
      return ajax("/turnstile/create.json", {
        data,
        type: "POST",
      })
        .then(() => {
          return originalAccountCreation(...arguments);
        })
        .catch(() => {
          turnstileService.failed = true;
          return Promise.reject();
        })
        .finally(() => {
          turnstileService.reset();
        });
    },
  });
}

export default {
  name: "turnstile-initializer",
  before: "inject-discourse-objects",

  initialize(container) {
    withPluginApi("1.9.0", (api) => initializeTurnstile(api, container));
  },
};
