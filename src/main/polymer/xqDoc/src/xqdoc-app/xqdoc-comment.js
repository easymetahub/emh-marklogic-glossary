import {PolymerElement, html} from '@polymer/polymer/polymer-element.js';
import '@vaadin/vaadin-grid/vaadin-grid.js';
import '@polymer/iron-collapse/iron-collapse.js';
import '@intcreator/markdown-element';
import 'prismjs/prism.js';

/**
 * @customElement
 * @polymer
 */
class XQDocComment extends PolymerElement {
  static get template() {
    return html`
    <style>
      :host {
        display: block;
        }
        div.unhealthy {
          background-color: red;
          height: 100%;
          width: 100%;
        }
    </style>
    <template is="dom-if" if="{{_isUnhealthy(showHealth, comment.description)}}">
      <div class="unhealthy">No xqDoc description exists</div>
    </template>
    <markdown-element markdown="[[comment.description]]"></markdown-element>
    <iron-collapse id="detailCollapse" opened="{{showDetail}}">
      <div class="conceptcard">
        <template is="dom-if" if="{{_showCommentDetails(comment)}}">
          <vaadin-grid  theme="compact wrap-cell-content column-borders row-stripes" items="{{_listDetail(comment)}}"  height-by-rows>
            <vaadin-grid-column>
              <template class="header">Type</template>
              <template>[[item.name]]</template>
            </vaadin-grid-column>
            <vaadin-grid-column>
              <template class="header">Description</template>
              <template><markdown-element markdown="[[item.comment]]"></markdown-element></template>
            </vaadin-grid-column>
          </vaadin-grid>
        </template>
        <template is="dom-if" if="{{_showParameters(parameters)}}">
          <h2>Parameters</h2>
          <vaadin-grid  theme="compact wrap-cell-content column-borders row-stripes" items="{{parameters}}"  height-by-rows>
            <vaadin-grid-column>
              <template class="header">Parameter</template>
              <template>[[item.name]]</template>
            </vaadin-grid-column>
            <vaadin-grid-column>
              <template class="header">Data Type</template>
              <template>
                <template is="dom-if" if="{{_isUnhealthy(showHealth, item.type)}}">
                  <div class="unhealthy">No data type specified for parameter.</div>
                </template>
                [[item.type]]
              </template>
            </vaadin-grid-column>
            <vaadin-grid-column>
              <template class="header">Occurrence</template>
              <template>[[item.occurrence]]</template>
            </vaadin-grid-column>
            <vaadin-grid-column>
              <template class="header">Description</template>
              <template>
                <template is="dom-if" if="{{_isUnhealthy(showHealth, item.description)}}">
                  <div class="unhealthy">No @param specified for this parameter in the xqDoc comment</div>
                </template>
                <markdown-element markdown="[[item.description]]"></markdown-element>
              </template>
            </vaadin-grid-column>
          </vaadin-grid>
        </template>
        <template is="dom-if" if="{{!return}}">
          <template is="dom-if" if="{{showHealth}}">
            <h2>Return</h2>
            <div class="unhealthy">No return type specified for this function</div>
          </template>
        </template>
        <template is="dom-if" if="{{return}}">
          <h2>Return</h2>
          <vaadin-grid  theme="compact wrap-cell-content column-borders row-stripes" items="{{_listReturn(return)}}"  height-by-rows>
            <vaadin-grid-column>
              <template class="header">Data Type</template>
              <template>[[item.type]]</template>
            </vaadin-grid-column>
            <vaadin-grid-column>
              <template class="header">Occurrence</template>
              <template>[[item.occurrence]]</template>
            </vaadin-grid-column>
            <vaadin-grid-column>
              <template class="header">Description</template>
              <template>
                <template is="dom-if" if="{{_isUnhealthy(showHealth, item.description)}}">
                  <div class="unhealthy">No @return specified in the xqDoc comment</div>
                </template>
                <markdown-element markdown="[[item.description]]"></markdown-element>
              </template>
            </vaadin-grid-column>
          </vaadin-grid>
        </template>
      </div>
    </iron-collapse>
    `;
  }
  static get properties() {
    return {
      comment: { type: Object },
      showHealth: { type: Boolean, notify: true },
      showDetail: {
        type: Boolean,
        notify: true
      },
      parameters: { type: Array },
      return: { type: Object }
    };
  }

  _showParameters(parameters) {
      if (parameters.length > 0) {
        return true;
      } else {
        return false;
      }
  }

  _showCommentDetails(comment) {
    if (comment) {
      if ((comment.authors.length + 
           comment.versions.length + 
           comment.errors.length + 
           comment.deprecated.length + 
           comment.see.length + 
           comment.since.length +
           comment.custom.length) > 0) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  _isUnhealthy(showHealth, testItem) {
    if (showHealth && (testItem == null || testItem.length == 0)) {
      return true;
    } else {
      return false;
    }
  }

  _listDetail(comment) {
    var detail = [];
    var idx2 = 0;

    if (comment.authors.length) {
      for (idx2 = 0; idx2 < comment.authors.length; idx2++) {
        detail.push({ name: "Author", comment: comment.authors[idx2] });
      }
    }
    if (comment.versions.length) {
      for (idx2 = 0; idx2 < comment.versions.length; idx2++) {
        detail.push({ name: "Version", comment: comment.versions[idx2] });
      }
    }
    if (comment.errors.length) {
      for (idx2 = 0; idx2 < comment.errors.length; idx2++) {
        detail.push({ name: "Error", comment: comment.errors[idx2] });
      }
    }
    if (comment.deprecated.length) {
      for (idx2 = 0; idx2 < comment.deprecated.length; idx2++) {
        detail.push({ name: "Deprecated", comment: comment.deprecated[idx2] });
      }
    }
    if (comment.see.length) {
      for (idx2 = 0; idx2 < comment.see.length; idx2++) {
        detail.push({ name: "See", comment: comment.see[idx2] });
      }
    }
    if (comment.since.length) {
      for (idx2 = 0; idx2 < comment.since.length; idx2++) {
        detail.push({ name: "Since", comment: comment.since[idx2] });
      }
    }
    if (comment.custom.length) {
      for (idx2 = 0; idx2 < comment.custom.length; idx2++) {
        detail.push({ name: comment.custom[idx2].tag, comment: comment.custom[idx2].description });
      }
    }
    return detail;
  }

  _listReturn(returnDescription) {
    var returns = [];
      returns.push(returnDescription);
    return returns;
  }
}

window.customElements.define('xqdoc-comment', XQDocComment);
