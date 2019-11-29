import {html, PolymerElement} from '@polymer/polymer/polymer-element.js';
import '@polymer/paper-item/paper-item.js';
/**
 *
 * @customElement
 * @polymer
 * @demo demo/index.html
 */
class ModuleSelector extends PolymerElement {
  static get template() {
    return html`
    <style>
      :host {
        display: block;
        padding-left: 5px;
      }
    </style>
    <paper-item></paper-item>
    `;
  }
  static get properties() {
    return {
      module: { type: Object, notify: true }
    };
  }

    checkboxChanged(event) {
      if (!this.selectedModule) this.selectedModule = [];
      
      if (event.target.checked) {
      this.push('selectedModule', event.target.name);
      } else {
        // remove selected module
      }
      this.notifyPath('selectedModule');
    }

}

window.customElements.define('module-selector', ModuleSelector);
