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
package com.ibm.mobilefirstplatform.clientsdk.cordovaplugins.core;

import android.content.Context;

import com.ibm.mobilefirstplatform.clientsdk.android.core.api.*;
import com.ibm.mobilefirstplatform.clientsdk.android.logger.api.*;

import com.ibm.mobilefirstplatform.clientsdk.android.security.api.AuthorizationManager;
import com.ibm.mobilefirstplatform.clientsdk.android.security.api.identity.AppIdentity;
import com.ibm.mobilefirstplatform.clientsdk.android.security.api.identity.DeviceIdentity;
import com.ibm.mobilefirstplatform.clientsdk.android.security.api.identity.UserIdentity;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.net.MalformedURLException;
import java.security.Policy;

/**
 * Created by rotembr on 10/22/15.
 */
public class CDVAuthorizationManager extends CordovaPlugin {

    private static final String TAG = "CDVAuthorizationManager";
    private static final Logger AMLogger = Logger.getInstance("CDVAuthorizationManager");

    private static final String PersistencePolicyAlways = "ALWAYS";
    private static final String PersistencePolicyNever = "NEVER";

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if ("obtainAuthorizationHeader".equals(action)) {
            this.obtainAuthorizationHeader(callbackContext);
            return true;
        } else if ("clearAuthorizationData".equals(action)) {
            this.clearAuthorizationData(callbackContext);
            return true;
        } else if ("isAuthorizationRequired".equals(action)) {
            this.isAuthorizationRequired(args, callbackContext);
            return true;
        } else if ("getCachedAuthorizationHeader".equals(action)) {
            this.getCachedAuthorizationHeader(callbackContext);
            return true;
        } else if ("getAuthorizationPersistencePolicy".equals(action)) {
            this.getAuthorizationPersistencePolicy(callbackContext);
            return true;
        } else if ("setAuthorizationPersistencePolicy".equals(action)) {
            this.setAuthorizationPersistencePolicy(args, callbackContext);
            return true;
        } else if ("getUserIdentity".equals(action)) {
            this.getUserIdentity(callbackContext);
            return true;
        } else if ("getAppIdentity".equals(action)) {
            this.getAppIdentity(callbackContext);
            return true;
        } else if ("getDeviceIdentity".equals(action)) {
            this.getDeviceIdentity(callbackContext);
            return true;
        }

        return false;
    }


    private void obtainAuthorizationHeader(final CallbackContext callbackContext) throws JSONException {

        final Context currentContext = this.cordova.getActivity();

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {

                AuthorizationManager.getInstance().obtainAuthorizationHeader(currentContext, new ResponseListener() {
                    @Override
                    public void onSuccess(Response response) {
                        try {
                            PluginResult result = new PluginResult(PluginResult.Status.OK, CDVMFPRequest.packJavaResponseToJSON(response));
                            AMLogger.debug("ObtainAuthorizationHeader: request successful.");
                            callbackContext.sendPluginResult(result);
                        } catch (JSONException e) {
                            callbackContext.error(e.getMessage());
                        }
                    }

                    @Override
                    public void onFailure(Response failResponse, Throwable t, JSONObject extendedInfo) {
                        try {
                            PluginResult result = new PluginResult(PluginResult.Status.ERROR, CDVMFPRequest.packJavaResponseToJSON(failResponse));
                            AMLogger.error("Failed to send request obtainAuthorizationHeader.");
                            callbackContext.sendPluginResult(result);
                        } catch (JSONException e) {
                            callbackContext.error(e.getMessage());
                        }
                    }
                });

            }
        });

    }

    private void clearAuthorizationData(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                AuthorizationManager.getInstance().clearAuthorizationData();
                AMLogger.debug("Authorization data cleared.");
                callbackContext.success();
            }
        });
    }

    private void isAuthorizationRequired(final JSONArray args, final CallbackContext callbackContext) throws JSONException {

        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                try {
                    int statusCode = args.getInt(0);
                    String responseAuthorizationHeader = args.getString(1);
                    boolean answer = AuthorizationManager.getInstance().isAuthorizationRequired(statusCode, responseAuthorizationHeader);
                    AMLogger.debug("isAuthorizationRequired return " + answer);
                    callbackContext.success(String.valueOf(answer));
                } catch (JSONException e) {
                    callbackContext.error(e.getMessage());
                }
            }
        });
    }


    private void getCachedAuthorizationHeader(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                String header = AuthorizationManager.getInstance().getCachedAuthorizationHeader();
                AMLogger.debug("Cached authorization header: " + header);
                callbackContext.success(header);
            }
        });
    }

    private void getAuthorizationPersistencePolicy(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                AuthorizationManager.PersistencePolicy policy = AuthorizationManager.getInstance().getAuthorizationPersistencePolicy();
                AMLogger.debug("PersistencePolicy:" + policy.toString());
                callbackContext.success(policy.toString());
            }
        });
    }

    private void setAuthorizationPersistencePolicy(final JSONArray args, final CallbackContext callbackContext) throws JSONException {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                String newPolicy = null;
                try {
                    newPolicy = args.getString(0).toUpperCase();
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                boolean success = true;
                if (newPolicy.equals(PersistencePolicyNever)) {
                    AuthorizationManager.getInstance().setAuthorizationPersistencePolicy(AuthorizationManager.PersistencePolicy.NEVER);
                } else if (newPolicy.equals(PersistencePolicyAlways)) {
                    AuthorizationManager.getInstance().setAuthorizationPersistencePolicy(AuthorizationManager.PersistencePolicy.ALWAYS);
                } else {
                    success = false;
                    AMLogger.debug("Policy cann't be recognized:" + newPolicy.toString());
                    callbackContext.error("The specified persistence policy is not supported.");
                }

                if (success) {
                    AMLogger.debug("PersistencePolicy set to:" + newPolicy.toString());
                    callbackContext.success();
                }
            }
        });
    }

    private void getUserIdentity(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                UserIdentity userIdentity = AuthorizationManager.getInstance().getUserIdentity();
                AMLogger.debug("userIdentity: " + userIdentity.toString());
                callbackContext.success(userIdentity.toString());
            }
        });
    }

    private void getAppIdentity(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                AppIdentity appIdentity = AuthorizationManager.getInstance().getAppIdentity();
                AMLogger.debug("appIdentity: " + appIdentity.toString());
                callbackContext.success(appIdentity.toString());
            }
        });
    }

    private void getDeviceIdentity(final CallbackContext callbackContext) {
        cordova.getThreadPool().execute(new Runnable() {
            public void run() {
                DeviceIdentity deviceIdentity = AuthorizationManager.getInstance().getDeviceIdentity();
                AMLogger.debug("deviceIdentity: " + deviceIdentity.toString());
                callbackContext.success(deviceIdentity.toString());
            }
        });
    }
}