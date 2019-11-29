import {PolymerElement, html} from '@polymer/polymer/polymer-element.js';
import '@polymer/paper-card/paper-card.js';
import '@polymer/paper-toolbar/paper-toolbar.js';
import './xqdoc-comment.js';

/**
 * @customElement
 * @polymer
 */
class ImportDetail extends PolymerElement {
  static get template() {
    return html`
    <style is="custom-style">
      :host {
        display: block;
        }
      paper-card {
        width: 100%;
        margin-bottom: 5px;
      }
      paper-toolbar {
        --paper-toolbar-background: grey;
      }
      .card-content {
        padding-top: 5px;
        padding-bottom: 5px;
      }
    </style>
      <paper-card>
        <paper-toolbar>
          <span slot="top" class="title">Import: [[item.uri]]</span>
        </paper-toolbar>
        <template is="dom-if" if="{{item.comment}}">
          <div class="card-content">
            <xqdoc-comment show-detail comment="[[item.comment]]"></xqdoc-comment>
          </div>
        </template>
      </paper-card>
    `;
  }
  static get properties() {
    return {
      item: { type: Object, notify: true }
    };
  }

}

window.customElements.define('import-detail', ImportDetail);
