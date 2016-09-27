////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component : Manacles system 
//
//  Signature : LGF/BOND/MANACLE/LEASH
//  LGF Version protocol : 1.1.0.0
//  Component version : 0.1
//  release date : Septmber 2016
//
//  Description : This component is leash  who can interact with LGF component leash holder
//                  
//
//  State description : 
//      
//                      
//
//  LGF interfaces implemented by this script (Please refer to LGF interfaces directory):
//            - LEASH
//
//  Messages sent by LEASH except those required by implemented interfaces (Please refer to LGF msg directory)
//
//  Messages handled by LEASH except those required by implemented interfaces (Please refer to LGF msg directory)
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

string      gVersion        = "0.10"; // version of the component
integer     gDebug          = 1;


integer CHANNEL_LGF_SLAVE          = - 7515; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_MASTER         = - 7516; // listen channel for register processing by LGF master object
string  HEADER_LEASH               = "LGF|BOND|MANACLE|LEASH|1.1.0.0|"; // LGF header message sent by object
string  ACTION_LEASH_REQ           = "LEASH_REQUEST";   // LGF Message body to leash
string  ACTION_LEASH_ACK           = "LEASH_REQUEST_ACK";   // LGF Message body to accept the leash
string  INTERF_LEASH_HOLDER        = "LEASH_HOLDER";
integer INDEX_REQ_ACTION           = 5;         // index in LGF message containing the REQUEST action

integer CHANNEL_DIALOG         = -6000;
integer MSG_FOLLOWER         = 7555;
integer MSG_OC_CUFFS_MENU    = 7554;

string gMenuHeader =  "LGF Leash system version ";
list gMenuItems = [];
string K_MENUITEM_LEASH         = "Leash";
string K_MENUITEM_UNLEASH         = "Unleash";
string K_MENUITEM_FOLLOWER_ON     = "Follower ON";
string K_MENUITEM_FOLLOWER_OFF     = "Follower OFF";


key     gKeyToucher = NULL_KEY;

integer gHandleHandleDialog = 0;
integer gHandleListenSlave = 0;

integer gFollowerActive = 1;
integer gLeashed         = 0;

// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

init_default() {
    gFollowerActive = 1;
    llParticleSystem([]);
}

RequestToleash() {
    // Send a request to leash
    gHandleListenSlave= llListen (CHANNEL_LGF_SLAVE,"", NULL_KEY, "");
    llRegionSay (CHANNEL_LGF_MASTER, HEADER_LEASH + ACTION_LEASH_REQ  + "|" + INTERF_LEASH_HOLDER);
}

Unleash() {
    llParticleSystem([]);
    
    // deactivate follower 
    llMessageLinked(LINK_THIS,MSG_FOLLOWER,"OFF",NULL_KEY);
    
    // delete the reference to the followed avi
    gKeyToucher = NULL_KEY;
    
    gLeashed = 0;
}

Leash(key pKeyLeashTo) {
    debug("creating leash.........");
    // leash creation
    llParticleSystem([  5,<3.0e-2,3.0e-2,3.0e-2>,
                        6,<5.0e-2,5.0e-2,5.0e-2>,
                        1,<1.0,1.0,1.0>,
                        3,<1.0,1.0,1.0>,
                        2,((float)1.0),
                        4,((float)1.0),
                        15,((integer)10),
                        13,((float)1.0e-3),
                        7,((float)10.0),
                        9,((integer)1),
                        8,<0.0,0.0,-0.1>,
                        0,((integer)355),
                        20,pKeyLeashTo]);
    
    gLeashed = 1;
     
    // send msg to follower  
    if (gFollowerActive ==1 ) {
        // activate follower
        llMessageLinked(LINK_THIS,MSG_FOLLOWER,"ON",gKeyToucher);
    } else { 
        // deactivate follower 
        llMessageLinked(LINK_THIS,MSG_FOLLOWER,"OFF",NULL_KEY);
    }               
}

activateFollower() {
    if (gKeyToucher != NULL_KEY) {
        // activate follower
        llMessageLinked(LINK_THIS,MSG_FOLLOWER,"ON",gKeyToucher);    
    }
    gFollowerActive =1;
}

deactivateFollower() {
    // deactivate follower 
    llMessageLinked(LINK_THIS,MSG_FOLLOWER,"OFF",NULL_KEY);
    gFollowerActive = 0;
}

doMenu(key pIDToucher) {
    gKeyToucher = pIDToucher;
    gHandleHandleDialog= llListen (CHANNEL_DIALOG,"", gKeyToucher, "");
    gMenuItems = [];
    
    if (gLeashed == 0) {
          gMenuItems +=[K_MENUITEM_LEASH];
      } else {
          gMenuItems +=[K_MENUITEM_UNLEASH];
      }
  
      if (gFollowerActive == 1) {
          gMenuItems += [K_MENUITEM_FOLLOWER_OFF];
      } else {
          gMenuItems += [K_MENUITEM_FOLLOWER_ON];
      }
  
      llDialog(gKeyToucher, gMenuHeader + gVersion, gMenuItems, CHANNEL_DIALOG);
}

default {
    state_entry() {
         init_default();  
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            llResetScript();
        }
    } 
    
    link_message(integer nSenderNum, integer nNum, string szMsg, key keyID)  {
        if (nNum == MSG_OC_CUFFS_MENU) {
            doMenu(keyID);
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (channel == CHANNEL_LGF_SLAVE) {
            debug("Message received in slave channel : " + message);
            // messages on the master channel are sent by worn devices

            // message received on the master channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                debug ("action = " + (string) action);
                if (action == ACTION_LEASH_ACK){
                    //leash
                    debug ("before test id");
                    if (llGetOwnerKey(id) == gKeyToucher) {
                        // The avi who touched is the avi who owns the object that answered
                        llListenRemove(gHandleListenSlave);
                        Leash(id);  
                    }                  
                }
            }
        } else if ((channel == CHANNEL_DIALOG) && ( id == gKeyToucher)) {
                llListenRemove(gHandleHandleDialog);
                if (message == K_MENUITEM_LEASH) {
                    debug("Send a request to leash");
                    RequestToleash();
                } else if (message == K_MENUITEM_UNLEASH) {
                    Unleash();
                } else if (message == K_MENUITEM_FOLLOWER_ON) {
                    // activate follower
                    activateFollower();
                } else if (message = K_MENUITEM_FOLLOWER_OFF) {
                    deactivateFollower();
                }
                
        }
        
    }   
    
}
