/*
    Copyright 2015 IBM Corp.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
var exec = require("cordova/exec");

var BMSClient = function() {
    this._backendRoute = "";
    this._backendGuid = "";
    this._challengeHandlers = {};

    var success = function() { console.log("Success: BMSClient initialization succeeded"); };
    var failure = function() { console.log("Error: BMSClient could not initialize"); };

    /**
     * Sets the base URL for the authorization server.
     * <p>
     * This method should be called before you send the first request that requires authorization.
     * </p>
     * @param {string} backendRoute Specifies the base URL for the authorization server
     * @param {string} backendGuid Specifies the GUID of the application
     */
    this.initialize = function(backendRoute, backendGuid) {
        this._backendRoute = backendRoute;
        this._backendGuid = backendGuid;
        cordova.exec(success, failure, "BMSClient", "initialize", [backendRoute, backendGuid]);
    };

    /**
     * Registers authentication callback for the specified realm.
     * @param {string} realm Authentication realm.
     * @param {function} authenticationListener
     */
    this.registerAuthenticationListener = function(realm, authenticationListener) {
        cordova.exec(success, failure, "BMSClient", "registerAuthenticationListener", [realm, authenticationListener]);
    };

    /**
     * Unregisters the authentication callback for the specified realm.
     * @param {function} authenticationListener
     */
    this.unregisterAuthenticationListener = function(authenticationListener) {
        cordova.exec(success, failure, "BMSClient", "unregisterAuthenticationListener", [authenticationListener]);
    };

    /**
     *
     * @return backendRoute
     */
    this.getBluemixAppRoute = function(callback) {
        //TODO : Completely implement once registerAuthenticationListener and unregisterAuthenticationListener are complete
        return this._backendRoute;
    };

    /**
     * 
     * @param backendGUID
     */
    this.getBluemixAppGUID = function(callback) {
        //TODO : Completely implement once registerAuthenticationListener and unregisterAuthenticationListener are complete
        return this._backendGuid;
    };
};

//Return singleton instance
module.exports = new BMSClient();