import {PolymerElement, html} from '@polymer/polymer/polymer-element.js';
import '@polymer/paper-card/paper-card.js';
import 'polymer-code-highlighter/code-highlighter.js';
import '@polymer/iron-collapse/iron-collapse.js';
import '@polymer/iron-icons/iron-icons.js';
import '@polymer/paper-toggle-button/paper-toggle-button.js';
import '@polymer/paper-icon-button/paper-icon-button.js';
import '@polymer/paper-toolbar/paper-toolbar.js';
import '@polymer/paper-button/paper-button.js';
import './xqdoc-comment.js';
import './hash-button.js';

/**
 * @customElement
 * @polymer
 */
class XQDocModule extends PolymerElement {
  static get template() {
    return html`
    <style is="custom-style">
      :host {
        display: block;
        }
      paper-toolbar {
        --paper-toolbar-background: grey;
      }
      paper-card {
        width: 100%;
        margin-bottom: 5px;
      }
      expanded-card {
        padding-top: 1px;
        padding-bottom: 1px;
      }
      paper-toggle-button {
        margin-right: 10px;
      }
      .card-content {
        padding-top: 5px;
        padding-bottom: 5px;
      }
    </style>
    <paper-card>
      <paper-toolbar>
        <span slot="top" class="title">Module: [[item.uri]]</span>
        <paper-toggle-button slot="top" checked="{{showDetail}}">Detail</paper-toggle-button>
        <paper-toggle-button slot="top" checked="{{showCode}}">Code</paper-toggle-button>
      </paper-toolbar>
      <div class="card-content">
      <xqdoc-comment show-detail="[[showDetail]]" show-health="[[showHealth]]" comment="[[item.comment]]"></xqdoc-comment>
        <iron-collapse id="detailCollapse" opened="{{showDetail}}">
          <div class="conceptcard">
          <template is="dom-if" if="{{_showInvoked(item)}}">
            <h4>Functions that are invoked in this function</h4>
            <vaadin-grid  theme="compact wrap-cell-content column-borders row-stripes" items="[[item.invoked]]"  height-by-rows>
              <vaadin-grid-column>
                <template class="header">Module URI</template>
                <template>[[item.uri]]</template>
              </vaadin-grid-column>
              <vaadin-grid-column>
                <template class="header">Function Names</template>
                <template>
                  <template is="dom-repeat" items="{{item.functions}}">
                    <hash-button name="[[item.name]]" uri="[[item.uri]]" disabled="[[!item.isReachable]]" params="{{params}}" hash="{{hash}}"></hash-button>
                  </template>
                </template>
              </vaadin-grid-column>
            </vaadin-grid>
          </template>
          <template is="dom-if" if="{{_showRefVariables(item)}}">
            <h4>Variables that are referred to in this function</h4>
            <vaadin-grid  theme="compact wrap-cell-content column-borders row-stripes" items="[[item.refVariables]]"  height-by-rows>
              <vaadin-grid-column>
                <template class="header">Module URI</template>
                <template>[[item.uri]]</template>
              </vaadin-grid-column>
              <vaadin-grid-column>
                <template class="header">Variable Names</template>
                <template>
                  <template is="dom-repeat" items="{{item.variables}}">
                    <paper-button class="label" noink>$[[item.name]]</paper-button>
                  </template>
                </template>
              </vaadin-grid-column>
            </vaadin-grid>
          </template>
          </div>
        </iron-collapse>
        <iron-collapse id="contentCollapse" opened="{{showCode}}">
          <div class="conceptcard">
            <code-highlighter>[[item.body]]</code-highlighter>
          </div>
        </iron-collapse>
      </div>
    </paper-card>
    `;
  }
  static get properties() {
    return {
      showCode: {
        type: Boolean,
        value: false,
        notify: true
      },
      showDetail: {
        type: Boolean,
        value: false,
        notify: true
      },
      params: { type: Object, notify: true },
      showHealth: { type: Boolean, notify: true },
      hash: { type: String, notify: true },
      item: { type: Object, notify: true }
    };
  }

    _showInvoked(item) {
      if (item.invoked.length > 0) {
        return true;
      } else {
        return false;
      }
    }

    _showRefVariables(item) {
      if (item.refVariables.length > 0) {
        return true;
      } else {
        return false;
      }
    }

}

window.customElements.define('xqdoc-module', XQDocModule);
