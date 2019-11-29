import {PolymerElement, html} from '@polymer/polymer/polymer-element.js';
import '@polymer/paper-button/paper-button.js';

/**
 * @customElement
 * @polymer
 */
class HashButton extends PolymerElement {
  static get template() {
    return html`
    <style>
    paper-button {
      padding-top: 4px;
      padding-bottom: 3px;
    }
    </style>
    <paper-button disabled="[[disabled]]" raised on-click="selectLink">[[name]]</paper-button>
    `;
  }
  static get properties() {
    return {
      name: { type: String, notify: true },
      uri: { type: String, notify: true  },
      disabled: { type: Boolean, value: false },
      params: { type: Object, notify: true },
      hash: { type: String, notify: true }
    };
  }

  selectLink() {
    var p = this.get('params');
    var m = p.module;
    if (m != this.uri) {
      this.set('params', { module: this.uri});
      this.notifyPath('params');
      setTimeout(
        () => this._setHash('function-' + this.name),
        2500
      );
    } else {
      this.hash = 'function-' + this.name;
    }
  }

  _setHash(newHash) {
    this.set('hash', newHash);
  }

}

window.customElements.define('hash-button', HashButton);
