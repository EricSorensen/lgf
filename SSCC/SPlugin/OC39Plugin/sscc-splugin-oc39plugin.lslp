////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component : OC 3.9 SSCC PLUGIN
//
//  Signature : LGF/SSCC/SPLUGIN/OC39PLUGIN
//  LGF Version protocol : 1.1.0.0
//  Component version : 0.1
//  release date : March 2016
//
//  Description : This component is the OC 3.9 Collar plugin. It allows an interaction
//                    with the SSCC Slave Hud
//
//  State description : Defaut is the state when the plugin is not initialized
//                      i.e not linked to his slave hud
//      
//                      Plugim is set to connected state once registered to one SSCC Slave hud
//
//  LGF interfaces implemented by this script (Please refer to LGF interfaces directory):
//            - SSCC-SLAVE-SUB
//
//  Messages sent by OC38PLUGIN except those required by implemented interfaces (Please refer to LGF msg directory)
//
//  Messages handled by OC38PLUGIN except those required by implemented interfaces (Please refer to LGF msg directory)
//
//  documentation : http://lgfsite.wordpress.com
//
//
//  copyright © Lady Green Forensic 2016
//
//  This script is free software: you can redistribute it and/or modify     
//  it under the terms of the creative commons Attribution- ShareAlike 4.0 
//  International licence. (http://creativecommons.org/licenses/by-sa/4.0/legalcode)
//
///////////////////////////////////////////////////////////////////////////////////////////////////

string     gVersion = "0.10"; // version of the component

string  gsScript= "oc39plugin_";
list    gOwners;        // list of owners
integer gDebug = 1;

integer gHandle                     = 0;
integer CHANNEL_LGF_MASTER          = - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE           = - 7515; // listen channel for register processing by LGF master object
string  HEADER_0C39SSCCPLUGIN       = "LGF|SSCC|SPLUGIN|OC39PLUGIN|1.1.0.0|"; // LGF header message sent by object
string  MSG_BODY_BLIIP              = "BLIIP";     // LGF Bliip message body
string  INTERFACE_PLUGIN_SLAVE      = "SSCC-SLAVE-SUB";
string  NACK                        = "NACK";     // REQUEST_ANSWER : Rejected
string  ALREADY_CONNECTED           = "ALREADY_CONNECTED";     // REQUEST_ANSWER : Already connected
string  ACK                         = "ACK";     // REQUEST_ANSWER : Rejected

integer INDEX_REQ_ACTION           	= 5;         // index in LGF message containing the REQUEST action
integer INDEX_REQ_INTERF           	= 7;         // index in LGF message containing the REQUEST action
integer INDEX_MASTER_UID           	= 7;         // index in LGF message containing the Master prim UUID
string  ACTION_REGISTER         	= "REGISTER";   // LGF Message body for LGF REGISTER
string  ACTION_REGISTER_ACK     	= "REGISTER_ANSWER";    // LGF Message body for LGF REGISTER ACKNOWLEDGE
string  ACTION_HEARTBEAT			= "ACTION_HEARTBEAT";	// Heartbeat Management

//OC 3.9 messages
integer LM_SETTING_RESPONSE = 2002;

key  gSlaveHudPrimKey       = NULL_KEY;    // Key of the HUD UUID associated with the titler

    
// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}
 
sendBlipMsg() {

    // Blip message has to be broadcaster on master Channel
    llRegionSay(CHANNEL_LGF_MASTER, HEADER_0C39SSCCPLUGIN + MSG_BODY_BLIIP + "|" + INTERFACE_PLUGIN_SLAVE);
    debug("broadcast bliip msg");
}

sendHeartbeat(key id) {
	if (id == gSlaveHudPrimKey) {
		llRegionSayTo (gSlaveHudPrimKey, CHANNEL_LGF_MASTER, HEADER_0C39SSCCPLUGIN + ACTION_HEARTBEAT);
	}
} 


integer actionRegisterHandler (list paramsMsg, string pSuccess, key pSender) {
    // A request to register is received and slave object is not yet initialized
    // we check if the emitter Prim's owner is the owner of ther titler
    // we store the UUID of the master Prim
    integer lReturn = FALSE;
    
    string lReqInterface =llList2String(paramsMsg,INDEX_REQ_INTERF);

    if (lReqInterface == INTERFACE_PLUGIN_SLAVE){
        // a SSCC SLAVE interface is required. we accept the request if owner of sender object 
        // is owner of collar
        debug ("interface plugin slave is required");
        
        list lDetails = llGetObjectDetails( pSender, ([OBJECT_OWNER]));
        key lKeyOwnerSender = llList2Key(lDetails,0);
        
        if (llListFindList(gOwners, [lKeyOwnerSender])>= 0) {
            // owner of SSCC_MASTER is in list of owner of collar
            // Handshake is accepted
            gSlaveHudPrimKey = pSender;
            llRegionSayTo (gSlaveHudPrimKey, CHANNEL_LGF_MASTER, HEADER_0C39SSCCPLUGIN + ACTION_REGISTER_ACK +"|" + INTERFACE_PLUGIN_SLAVE + "|" + pSuccess);
                            
            // we change the state to connected
            lReturn = TRUE;
        } else {
            // Master hud owner is not declarer as owner of collar
            // we reject the request
            //llRegionSayTo (pSender, CHANNEL_LGF_MASTER, HEADER_0C39SSCCPLUGIN + ACTION_REGISTER_ACK +"|" + + INTERFACE_PLUGIN_SLAVE + "|" + NACK);
        }
                        
                       
    } else {
        debug ("interface required :" + lReqInterface);
        // a non SSCC SLAVE interface is required. we rejetct the request
       // llRegionSayTo (pSender, CHANNEL_LGF_MASTER, HEADER_0C39SSCCPLUGIN + ACTION_REGISTER_ACK +"|" + NACK);
    }
    
    return lReturn;
                    
}

default {
    state_entry() {
        
        key ltemp = "9f8741dd-bcac-4269-8f17-14af5b15e068";
        gOwners +=[ltemp];
        gOwners +=["eric.sorensen"];
        
        
        // Prim listen the Slave channel
        gHandle = llListen(CHANNEL_LGF_SLAVE, "","","");
        
        // Send blip message to tell to master that object is ready to receive message
        sendBlipMsg();
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        
        if (iNum == LM_SETTING_RESPONSE) {
            // retrieve the owner's list
            string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) {
                gOwners = llParseString2List(sValue, [","], []);
                // pair = key, impair = nom
                
            } else if (sGroup == gsScript) {
                // loading activity report 
                //sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
                //debug ("Entrée sGroup fanclub pour token " + sToken);
                //if(sToken == "active") {
                //    debug ("Entrée sToken active");
                //    if (sValue== "0") {
                //        DeactivateReport();
                //    } else if (sValue=="1") {
                //        if (gActive == 0) {
                //            ActivateReport();
                //        }
                //    }
                //} else if (sToken == "debug") {
                //    if (sValue== "0") {
                //        gDebug = 0;
                //    } else {
                //        gDebug = 1;
                //    } 
                //} else if (sToken == "Whitelist") {
                //    gWhiteList = llParseString2List(sValue, [","], []);
                //} else if (sToken == "Blacklist") { 
                //    gBlackList = llParseString2List(sValue, [","], []);
                //}
            }
            
        } 
    }
    
    //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            llResetScript();
        }
    }    
    
    listen(integer channel, string name, key id, string message) {
       
        if (channel == CHANNEL_LGF_SLAVE) {
            debug("Message received in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                debug ("message received :" + action);
                if (action == ACTION_REGISTER){
                    integer lReturn = actionRegisterHandler(paramsMsg, ACK, id);
                    
                    if (lReturn == TRUE) {
                        state connected;
                    } 
                    return;
                }                
            
            }
        }
    }
}

state connected {
    state_entry (){
        // we start listening on the slave channel if required
        gHandle = llListen(CHANNEL_LGF_SLAVE, "", gSlaveHudPrimKey,""); 
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    listen(integer channel, string name, key id, string message) {
       
        if (channel == CHANNEL_LGF_SLAVE) {
            debug ("Message received in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if (action == ACTION_REGISTER){
                    // A request to register is received and slave object is not yet initialized
                    // we check if the emitter Prim's owner is the owner of ther titler
                    // we store the UUID of the master Prim
                    actionRegisterHandler(paramsMsg, ALREADY_CONNECTED, id);
                    return;
                }
                
                if (action == ACTION_HEARTBEAT) {
                	sendHeartbeat(id);
                	return;
                }
                
                
            
            }
        }
    }
}