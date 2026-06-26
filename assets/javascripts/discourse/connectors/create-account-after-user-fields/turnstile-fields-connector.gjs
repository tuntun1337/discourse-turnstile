import Component from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import Turnstile from "../../components/turnstile";

@tagName("")
@classNames(
  "create-account-after-user-fields-outlet",
  "turnstile-fields-connector"
)
export default class TurnstileFieldsConnector extends Component {
  <template>
    <div class="input-group">
      <Turnstile @siteKey={{this.siteSettings.turnstile_site_key}} />
    </div>
  </template>
}
