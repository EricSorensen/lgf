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
//  Description : This component is a titler which can interact with one LGF component
//                using the LGF protocol active objects integration 
//                During LGF handshake, the titler registers the LGF master component 
//                and wait for a message from it to display or to clean.
//
//  State description : Defaut is the state when the titler is not initialized
//                      i.e not linked to his hud
//      
//                      Titler is set to active state once registered to one LGF master object
//
//  Messages sent by Titler (Please refer to LGF msg directory)
//              - BLIIP
//              - REGISTER_ANSWER
//
//  Message managed by Titler (Please refer to LGF msg directory)
//              - REGISTER_REQUEST
//              - SET_TITLER
//              = UNSET_TITLER
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

string gVersion = "0.10"; // version of the component

string gsScript= "oc39plugin_";
list gOwners;        // list of owners

integer gHandle            		= 0;
integer CHANNEL_LGF_MASTER 		= - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE  		= - 7515; // listen channel for register processing by LGF master object
string  HEADER_TITLER			= "LGF|SSCC|SPLUGIN|OC39PLUGIN|1.1.0.0|"; // LGF header message sent by object
string  MSG_BODY_BLIIP   		= "BLIIP";     // LGF Bliip message body
string  INTERFACE_SSCC_MASTER   = "SSCC-MASTER";     // LGF Bliip message body
string  INTERFACE_SSCC_SLAVE    = "SSCC-SLAVE";     // LGF Bliip message body
string  NACK					= "NACK";     // REQUEST_ANSWER : Rejected
string  ALREADY_CONNECTED		= "ALREADY_CONNECTED";     // REQUEST_ANSWER : Already connected

integer INDEX_REQ_ACTION   		= 5;         // index in LGF message containing the REQUEST action
integer INDEX_REQ_INTERF   		= 6;         // index in LGF message containing the REQUEST action
integer INDEX_MASTER_UID   		= 7;         // index in LGF message containing the Master prim UUID
string  ACTION_REGISTER     	= "REGISTER_REQUEST";   // LGF Message body for LGF REGISTER
string  ACTION_REGISTER_ACK 	= "REGISTER_ANSWER";    // LGF Message body for LGF REGISTER ACKNOWLEDGE


key  gMasterHudPrimKey       = NULL_KEY;    // Key of the HUD UUID associated with the titler

    
// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}
 
sendBlipMsg() {

    // Blip message has to be broadcaster on master Channel
    llRegionSay(CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + MSG_BODY_BLIIP + "|" + INTERFACE_SSCC_MASTER + "|" + (string) llGetKey () );
    debug("broadcast bliip msg");
} 

default {
    state_entry() {
        
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
                //debug("list of owners received :" + (string)gOwners);
                
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
            log("Message received in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if (action == ACTION_REGISTER){
                    // A request to register is received and slave object is not yet initialized
                    // we check if the emitter Prim's owner is the owner of ther titler
                    // we store the UUID of the master Prim
					string lReqInterface =llList2String(paramsMsg,INDEX_REQ_INTERF);

					if (lReqInterface == INTERFACE_SSCC_SLAVE){
						// a SSCC SLAVE interface is required. we accept the request if owner of sender object 
						// is owner of collar
						masterPrimKey = llList2Key(paramsMsg, INDEX_MASTER_UID);
						list lDetails = llGetObjectDetails( masterPrimKey, ([OBJECT_OWNER]));
						key lKeyOwnerSender = llList2Key(lDetails,0);
						
						if (llListFindList(gOwners, [lKeyOwnerSender])> 0) {
							// owner of SSCC_MASTER is in list of owner of collar
							// Handshake is accepted
							llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + (string)llGetKey());
							
							// we change the state to connected
							state connected;
						} else {
							// Master hud owner is not declarer as owner of collar
							// we reject the request
							llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + NACK);
						}
						
                        
					} else {
						// a non SSCC SLAVE interface is required. we rejetct the request
                        llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + NACK);
					}
                    
                }
                
            
            }
        }
    }
}

state connected {
    state_entry (){
        // we start listening on the slave channel if required
        lh = llListen(CHANNEL_LGF_SLAVE, "","",""); 
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    listen(integer channel, string name, key id, string message) {
       
        if (channel == CHANNEL_LGF_SLAVE) {
            log("Message received in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if (action == ACTION_REGISTER){
                    // A request to register is received and slave object is not yet initialized
                    // we check if the emitter Prim's owner is the owner of ther titler
                    // we store the UUID of the master Prim
					string lReqInterface =llList2String(paramsMsg,INDEX_REQ_INTERF);

					if (lReqInterface == INTERFACE_SSCC_SLAVE){
						// a SSCC SLAVE interface is required. we accept the request if owner of sender object 
						// is owner of collar
						masterPrimKey = llList2Key(paramsMsg, INDEX_MASTER_UID);
						list lDetails = llGetObjectDetails( masterPrimKey, ([OBJECT_OWNER]));
						key lKeyOwnerSender = llList2Key(lDetails,0);
						
						if (llListFindList(gOwners, [lKeyOwnerSender])> 0) {
							// owner of SSCC_MASTER is in list of owner of collar
							// Handshake is rejected because 
							llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + ALREADY_CONNECTED);
							
							// we change the state to connected
							state connected;
						} else {
							// Master hud owner is not declarer as owner of collar
							// we reject the request
							llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + NACK);
						}
						
                        
					} else {
						// a non SSCC SLAVE interface is required. we rejetct the request
                        llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + NACK);
					}
                    
                }
                
            
            }
        }
    }
}