/*
  Copyright (c) 2019. EasyMetaHub, LLC
 */
import {html, PolymerElement} from '@polymer/polymer/polymer-element.js';
import {timeOut} from '@polymer/polymer/lib/utils/async.js';
import {Debouncer} from '@polymer/polymer/lib/utils/debounce.js';
import '@polymer/app-layout/app-drawer-layout/app-drawer-layout.js';
import '@polymer/app-layout/app-drawer/app-drawer.js';
import '@polymer/app-layout/app-scroll-effects/app-scroll-effects.js';
import '@polymer/app-layout/app-header/app-header.js';
import '@polymer/app-layout/app-header-layout/app-header-layout.js';
import '@polymer/app-layout/app-toolbar/app-toolbar.js';
import '@polymer/app-layout/demo/sample-content.js';
import '@polymer/iron-icons/iron-icons.js';
import '@polymer/iron-icon/iron-icon.js';
import '@polymer/paper-icon-button/paper-icon-button.js';
import '@polymer/paper-button/paper-button.js';
import '@polymer/paper-card/paper-card.js';
import '@polymer/paper-dialog/paper-dialog.js';
import '@polymer/paper-input/paper-input.js';
import '@polymer/paper-slider/paper-slider.js';
import '@polymer/paper-spinner/paper-spinner.js';
import '@polymer/iron-location/iron-location.js';
import '@polymer/iron-location/iron-query-params.js';
import '@polymer/paper-button/paper-button.js';
import '@polymer/paper-dialog/paper-dialog.js';
import '@polymer/paper-dialog-scrollable/paper-dialog-scrollable.js';
import '@polymer/iron-ajax/iron-ajax.js';
import './result-item.js';
import './facet-card.js';
import 'paper-pagination/paper-pagination.js';
 
/**
 * @customElement
 * @polymer
 */
class EMHAcceleratorApp extends PolymerElement {
  static get template() {
    return html`
      <style is="custom-style">
        :host {
          display: block;
          background-color: lightgrey;
        }
      app-drawer-layout {
        background-color: lightgrey;
      }
      app-toolbar {
        background-color: grey;
        color: #fff;
      }
      app-drawer-layout:not([narrow]) [drawer-toggle] {
        display: none;
      }
        .counter {
          padding: 0px 0px 0px 16px;
        }
        section {
          overflow: scroll;
          height: 100%;
          background-color: lightgrey;
        }
        paper-item {
          cursor: pointer;
        }
        result-item {
          margin: 5px;
        }
        paper-dialog.wide {
          width: 90%;
        }
        paper-card {
          width: 100%;
          font-size: 10px;
          margin: 5px;
        }
        .emhLink {
          color: white;
        }
      </style>
      <iron-location id="sourceLocation" query="{{query}}"></iron-location>
      <iron-query-params id="sourceParams" params-string="{{query}}" params-object="{{params}}"></iron-query-params>
      <iron-ajax id="runSearch"
        url="/search"  
        params="[[params]]"
        handle-as="json"
        on-response="_onSearchResponse"></iron-ajax>
      <iron-ajax auto="true"  id="whoAmI"
        url="/session/status"  
        handle-as="json"
        last-response="{{user}}"></iron-ajax>
      <iron-ajax id="loginAction" 
        url="/session/login"  
        method="post"
        content-type="application/json"
        body="[[loginData]]"
        handle-as="json"
        on-response="_onLoginResponse"></iron-ajax>
      <iron-ajax id="logoutAction" 
        url="/session/logout"  
        handle-as="json"
        on-response="_onLogoutResponse"></iron-ajax>
      <paper-dialog class="wide" id="login">
        <h2>Login</h2>
        <paper-input label="username" value="{{loginData.user}}"></paper-input>
        <paper-input label="password" value="{{loginData.password}}" type="password"></paper-input>
        <div class="buttons">
          <paper-button dialog-dismiss>Close</paper-button>
          <paper-button on-click="_attemptUserLogin">Login</paper-button>
        </div>
      </paper-dialog>
      <paper-dialog id="userdata">
        <h2>Roles for [[user.user]]</h2>
        <vaadin-grid  theme="compact wrap-cell-content column-borders row-stripes" items="[[user.role]]"  height-by-rows>
          <vaadin-grid-column>
            <template class="header">ID</template>
            <template>[[item]]</template>
          </vaadin-grid-column>
        </vaadin-grid>
      </paper-dialog>
      <paper-dialog id="thespinner" modal>
        <paper-spinner active></paper-spinner>
      </paper-dialog>
      <app-drawer-layout>
        <app-drawer slot="drawer">
          <app-toolbar>
            <div main-title>Facets</div>
          </app-toolbar>
        <section>
          <template is="dom-repeat" items="{{result.facets}}" as="facet">
            <template is="dom-if" if="{{facet.values}}">
              <facet-card facet="{{facet}}"></facet-card>
            </template>
          </template>
          <div style="margin-bottom:90px;width:100%;"></div>
        </section>
        </app-drawer>
        <app-header-layout>
          <app-header slot="header" reveals effects="waterfall">
          <app-toolbar>
            <paper-icon-button icon="menu" drawer-toggle></paper-icon-button>
            <img src="/images/icon.svg" height="50%"/>
            <div main-title>Glossary</div>
            <paper-slider title="Page size" pin snaps min="10" max="100" step="10" value="{{params.pagelength}}"></paper-slider>
            <paper-icon-button icon="description" on-click="_goXQDoc"></paper-icon-button>
            <paper-icon-button icon="fingerprint" on-click="_goOpenAPI"></paper-icon-button>
            <template is="dom-if" if="[[_isAdmin(user)]]">
              <paper-icon-button icon="settings" on-click="_goAdmin"></paper-icon-button>
            </template>
            <paper-icon-button on-click="_openUserDialog" icon="face"></paper-icon-button>
            <template is="dom-if" if="[[!_isLoggedIn(user.user)]]">
              <paper-icon-button on-click="_openLoginDialog" icon="lock"></paper-icon-button>
            </template>
            <template is="dom-if" if="[[_isLoggedIn(user.user)]]">
              <paper-icon-button on-click="_attemptUserLogout" icon="close" raised></paper-icon-button>
            </template>
          </app-toolbar>
          </app-header>
          <paper-card>
            <paper-input id="searchInput" source="{{suggestions}}" value="{{search}}" placeholder="Query text">
              <paper-icon-button slot="suffix" on-click="clearInput" icon="clear" alt="clear" title="clear">
              </paper-icon-button>
            </paper-input>
          </paper-card>
          <paper-card>
            <div class="totalcounter">Total Count: [[_formatNumber(result.total)]] of [[_formatNumber(result.available)]]</div>
            <paper-pagination id="paginator" range-size="5" page-size="[[params.pagelength]]" total="[[result.total]]" offset="{{params.start}}"></paper-pagination>
          </paper-card>
        <section>
          <template is="dom-repeat" items="{{result.results}}">
            <result-item item="{{item}}" params="{{params}}" user="{{user}}"></result-item>
          </template>
          <!-- DO NOT REMOVE COPYRIGHT NOTICE -->
          <paper-card>Copyright &#169; 2018 EasyMetaHub, LLC. All rights reserved.</paper-card>
          <div style="margin-bottom:200px;height:150px;width:100%;"></div>
        </section>
        </app-header-layout>
      </app-drawer-layout>
    `;
  }
  static get properties() {
    return {
      suggestions: { type: Array, notify: true },
      result: { type: Object, notify: true },
      params: { type: Object, notify: true },
      search : {
        type : String,
        notify : true,
        observer : 'searchChanged'
      },
      user: { type: Object, notify: true },
      loginData: { type:Object, value: { }, notify: true }
    };
  }
    static get observers() {
      return [
      'facetChanged(result.facets.*)',
      'facetChanged2(params.selected)'
    ]
    } 

    clearInput() {
      this.search = "";
      this.params.q = "";
      this.params.facets = "";
      this.searchChanged();
    }

    searchChanged() {
      this._debouncer = Debouncer.debounce(
          this._debouncer, // initially undefined
          timeOut.after(1000),
          () => {
            this.params.q = this.search;
            this.notifyPath('params.q');
            this._runSearch();
          }
      );
    }

    facetChanged(value) {
      if (value.path.endsWith(".selected")) {
        var separator = "~~";
        var pathlength = value.path.length;
        var trimmed = value.path.substr(0, pathlength - 9);
        var item = this.get(trimmed);
        if (typeof item == 'undefined') {
          this.set( 'params.facets', ''  );
          this.notifyPath('params.facets');
          return;
        }
        var params = this.get("params");
        console.log("facet changed " + value);
        if (item.selected) {
          if (params.facets) {
            params.facets += separator + item.value;
          } else {
            params.facets = item.value;
          }
        } else {
          var tArray = params.facets.split(separator);
          var idx = tArray.indexOf(item.value);
          if (idx >= 0) {
            tArray.splice(idx, 1);
          }
          params.facets = tArray.join(separator);
        }
        this.set( 'params.facets', params.facets  );
        this.notifyPath('params.facets');
        this._runSearch();
      }
    }

    facetChanged2(value) {
      this._runSearch();
    }

    ready() {
      super.ready();
      if (!this.params.pagelength) {
        this.params.pagelength = 10;
        this.notifyPath('params.pagelength');
      }
    }

    connectedCallback() {
      super.connectedCallback();
      if (!this.params.pagelength) {
        this.params.pagelength = 10;
        this.notifyPath('params.pagelength');
      }
      this._runSearch();
    }

    _openDialog() {
      var d = this.$.dialog;
      var upload = this.$.responseDemo;

      upload.addEventListener('upload-response', function(event) {
        var results = JSON.parse(event.detail.xhr.response);
        console.log('upload xhr after server response: ', event.detail.xhr);
        
        if (results.errorResponse) {
          event.detail.file.messages = [{'type': 'fatal', 'message': results.errorResponse.message }];
        } else {
          if (results[0].responseFilename) {
            event.detail.file.responseFilename = results[0].responseFilename;
            event.detail.file.location = results[0].location;
            if (results[0].messages.length) {
              event.detail.file.messages = results[0].messages;
            }
          }
        }
      });
      this.$.dialog.open();
    }

    _goAdmin() {
      window.location = "admin/index.html";
    }

    _goXQDoc() {
      window.open('xqDoc/', '_blank');
    }

    _goOpenAPI() {
      window.open('openapi/', '_blank');
    }

    _runSearch() {
        this.$.thespinner.open();
        this.$.runSearch.generateRequest();
    }

    _onSearchResponse(e) {
      var resp = e.detail.response;
        this.$.thespinner.close();
      this.result = resp;
    }

    _closeUpload() {
      this._runSearch();
      this.$.dialog.close();
    }


    _openUserDialog() {
      this.$.userdata.open();
    }

    _openLoginDialog() {
      this.$.login.open();
    }

    _attemptUserLogin() {
      var a = this.loginData;
      this.$.loginAction.generateRequest();
    }

    _onLoginResponse(e) {
      this.$.whoAmI.generateRequest();
      this._runSearch();
      this.$.login.close();
    }

    _attemptUserLogout() {
      this.$.logoutAction.generateRequest();
    }

    _onLogoutResponse(e) {
      this.$.whoAmI.generateRequest();
    }

    _isLoggedIn(a) {
      return (a != 'emh-glossary-reader');
    }

    /**
     *
     * @param a
     * @returns {boolean}
     * @private
     */
  _isAdmin(a) {
    return (a.role.indexOf("emh-glossary-writer") > -1);
  }

    _formatNumber(x) {
      if (x == null) {
        x = 0;
      }
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

}

window.customElements.define('emh-accelerator-app', EMHAcceleratorApp);
