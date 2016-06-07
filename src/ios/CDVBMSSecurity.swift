/*
*     Copyright 2016 IBM Corp.
*     Licensed under the Apache License, Version 2.0 (the "License");
*     you may not use this file except in compliance with the License.
*     You may obtain a copy of the License at
*     http://www.apache.org/licenses/LICENSE-2.0
*     Unless required by applicable law or agreed to in writing, software
*     distributed under the License is distributed on an "AS IS" BASIS,
*     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*     See the License for the specific language governing permissions and
*     limitations under the License.
*/

import Foundation
import BMSCore
import BMSSecurity

enum PersistencePolicy: String {
    case PersistencePolicyAlways = "ALWAYS"
    case PersistencePolicyNever = "NEVER"
}

@objc(CDVBMSSecurity) class CDVBMSSecurity : CDVPlugin {
    
    static var jsChallengeHandlers: [String:CDVInvokedUrlCommand] = [:]
    static var authenticationContexts: [String:Any] = [:]
    
    static let bmsLogger = Logger.logger(forName: Logger.bmsLoggerPrefix + "CDVBMSSecurity")
    
    func obtainAuthorizationHeader(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            mcaAuthManager.obtainAuthorization(completionHandler: { (response, error) -> Void in
                
                let message = Utils.packResponse(response!, error: error)
                
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsDictionary: message)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                }
                else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: message)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                }
            })
            
        })
    }
    
    func isAuthorizationRequired(command: CDVInvokedUrlCommand) {
    
        self.commandDelegate!.runInBackground({
            
            guard let statusCode = command.arguments[0] as? Int else {
                let message = "Invalid status code"
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: message)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            
            guard let httpHeader = command.arguments[0] as? String else {
                let message = "Invalid HTTP response authorization header"
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: message)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
                return
            }
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            let req = mcaAuthManager.isAuthorizationRequired(forStatusCode: statusCode, httpResponseAuthorizationHeader: httpHeader)
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool: req)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func clearAuthorizationData(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            mcaAuthManager.clearAuthorizationData()
            
            let message = "Cleared authorization data"
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: message)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getCachedAuthorizationHeader(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            if let header: String = mcaAuthManager.cachedAuthorizationHeader {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: header)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
            }
            else {
                let message = "There is no cached authorization header"
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: message)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId: command.callbackId)
            }
        })
    }
    
    func getUserIdentity(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            var jsonResponse: [String : AnyObject] = [:]
            
            jsonResponse["authBy"] = mcaAuthManager.userIdentity!.authBy
            jsonResponse["displayName"] = mcaAuthManager.userIdentity!.displayName
            jsonResponse["id"] = mcaAuthManager.userIdentity!.id
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: jsonResponse)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getAppIdentity(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            var jsonResponse: [String : AnyObject] = [:]
            
            jsonResponse["id"] = mcaAuthManager.appIdentity.id
            jsonResponse["version"] = mcaAuthManager.appIdentity.version
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: jsonResponse)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getDeviceIdentity(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            var jsonResponse: [String : AnyObject] = [:]
            
            jsonResponse["id"] = mcaAuthManager.deviceIdentity.id
            jsonResponse["model"] = mcaAuthManager.deviceIdentity.model
            jsonResponse["OS"] = mcaAuthManager.deviceIdentity.OS
            jsonResponse["OSVersion"] = mcaAuthManager.deviceIdentity.OSVersion
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: jsonResponse)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getAuthorizationPersistencePolicy(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            let policy = mcaAuthManager.authorizationPersistencePolicy()
            var pluginResult: CDVPluginResult? = nil
            
            switch policy {
            case BMSCore.PersistencePolicy.ALWAYS:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: PersistencePolicy.PersistencePolicyAlways.rawValue)
            case BMSCore.PersistencePolicy.NEVER:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: PersistencePolicy.PersistencePolicyNever.rawValue)
            default:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Invalid Persistence Policy type")
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func setAuthorizationPersistencePolicy(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance
            
            guard var policy = command.arguments[0] as? String else {
                let message = "Invalid policy specified"
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: message)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                return
            }
            
            switch policy {
            case PersistencePolicy.PersistencePolicyAlways.rawValue:
                mcaAuthManager.setAuthorizationPersistencePolicy(BMSCore.PersistencePolicy.ALWAYS)
            case PersistencePolicy.PersistencePolicyNever.rawValue:
                mcaAuthManager.setAuthorizationPersistencePolicy(BMSCore.PersistencePolicy.NEVER)
            default:
                mcaAuthManager.setAuthorizationPersistencePolicy(BMSCore.PersistencePolicy.NEVER)
                policy = "NEVER"
            }
            
            let message = "Set persistence policy to \(policy)"
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: message)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func logout(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            let mcaAuthManager = MCAAuthorizationManager.sharedInstance;
            
            mcaAuthManager.logout({ (response, error) -> Void in
                let message = Utils.packResponse(response!, error: error)
                if (error != nil) {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsDictionary: message)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                }
                else {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: message)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                }
            })
        });
    }
    
    func registerAuthenticationListener(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            var errorText: String = ""
            
            do {
                let realm = try self.unpackRealm(command);
                let mcaAuthManager = MCAAuthorizationManager.sharedInstance
                let delegate = InternalAuthenticationDelegate(realm: realm, commandDelegate: self.commandDelegate!)
                
               mcaAuthManager.registerAuthenticationDelegate(delegate, realm: realm)
                
                defer {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: errorText)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                }
                
            } catch CustomErrors.InvalidParameterType(let expected, let actual) {
                errorText = CustomErrorMessages.invalidParameterTypeError(expected, actual: actual)
            } catch CustomErrors.InvalidParameterCount(let expected, let actual) {
                errorText = CustomErrorMessages.invalidParameterCountError(expected, actual: actual)
            } catch {
                errorText = CustomErrorMessages.unexpectedError
            }
        })
    }
    
    func addCallbackHandler(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            var errorText: String = ""
            
            do {
                let realm = try self.unpackRealm(command)
                CDVBMSSecurity.jsChallengeHandlers[realm] = command
                
                defer {
                    if (!errorText.isEmpty) {
                        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: errorText)
                        pluginResult.setKeepCallbackAsBool(true)
                        self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                    }
                }
                
            } catch CustomErrors.InvalidParameterType(let expected, let actual) {
                errorText = CustomErrorMessages.invalidParameterTypeError(expected, actual: actual)
            } catch CustomErrors.InvalidParameterCount(let expected, let actual) {
                errorText = CustomErrorMessages.invalidParameterCountError(expected, actual: actual)
            } catch {
                errorText = CustomErrorMessages.unexpectedError
            }
        })
    }
    
    private func unpackRealm(command: CDVInvokedUrlCommand) throws -> String {
        if (command.arguments.count < 1) {
            throw CustomErrors.InvalidParameterCount(expected: 1, actual: 0)
        }
        
        guard let realm = command.argumentAtIndex(0) as? String else {
            throw CustomErrors.InvalidParameterType(expected: "String", actual: command.argumentAtIndex(0))
        }
        
        return realm
    }

    internal class InternalAuthenticationDelegate: AuthenticationDelegate {
        
        var realm: String
        var commandDelegate: CDVCommandDelegate
        
        init(realm: String, commandDelegate: CDVCommandDelegate) {
            self.realm = realm
            self.commandDelegate = commandDelegate
        }
        
        internal func onAuthenticationChallengeReceived(authContext: AuthenticationContext, challenge: AnyObject) {
            
            let command: CDVInvokedUrlCommand = jsChallengeHandlers[realm]!
            let jsonResponse: [NSString: AnyObject] = ["action": "onAuthenticationChallengeReceived", "challenge": challenge];
            
            CDVBMSSecurity.authenticationContexts[realm] = authContext
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: jsonResponse)
            pluginResult.setKeepCallbackAsBool(true)
            commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        }
        
        internal func onAuthenticationSuccess(info: AnyObject?) {

            let command: CDVInvokedUrlCommand = jsChallengeHandlers[realm]!
            let jsonResponse: [NSString: AnyObject] = ["action": "onAuthenticationSuccess", "info": info!];
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: jsonResponse)
            commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        }
        
        internal func onAuthenticationFailure(info: AnyObject?) {
            
            let command: CDVInvokedUrlCommand = jsChallengeHandlers[realm]!
            let jsonResponse: [NSString: AnyObject] = ["action": "onAuthenticationFailure", "info": info!];
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary: jsonResponse)
            pluginResult.setKeepCallbackAsBool(true)
            commandDelegate.sendPluginResult(pluginResult, callbackId: command.callbackId)
        }
    }
}