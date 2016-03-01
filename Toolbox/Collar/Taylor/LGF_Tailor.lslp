////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : TAILOR
//
//  Signature                         : LGF/APPS/COLLAR/TAILOR
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.11
//  release date                      : December 2015
//
//  Description : This component is an OC Apps. It allows the owner to receive a report
//                    of attachments worn by the sub/slave
//
//  State description : Defaut is the only state used 
//
//  Messages sent by TAILOR (Please refer to LGF msg directory)
//
//  Message managed by TAILOR (Please refer to LGF msg directory)
//
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////

string gVersion = "0.11"; // version of the component
string gsParentMenu = "Apps"; // Root menu fot this apps
string gsFeatureName = "Tailor"; // Name of the menu of this apps
string gsScript= "taylor_";     // used for parameters save
integer gActive = 0;
integer gDebug = 0;

float K_TIMER_DELAY = 600.0; // 10 min between two reports computation

string MENU_CHOICE_ACTIVATE = "Activate";
string MENU_CHOICE_DEACTIVATE = "Deactivate";
string MENU_CHOICE_DEBUG_OFF = "Debug OFF";
string MENU_CHOICE_DEBUG_ON = "Debug ON";


// OC Collar events
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_SAVE = 2000;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
string UPMENU = "BACK";

// Global script variables
list gOwners;        // list of owners
key gkDialogID;    //menu handle
string gWearerName;

//Report management
integer gListenerReport;
integer gChannelReport;
list gCurrentAttachments;
list gDataOnlineRequest;// LGF update
integer LM_SEND_EMAIL = 3500; // message to send an email instead of an im

// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

// This function gets the list of attachments
list getAttachments() {
    
    // we get all attachments. 
    list lTemp = llGetAttachedList(llGetOwner());
    integer iStop = llGetListLength(lTemp);
    integer n = 0;
    debug ("Number of Attachments : " + (string)iStop);
    //returned value
    list lReturn;
    
    for (n = 0; n < iStop; n += 1) {
        
        key lUUID = llList2Key(lTemp,n);
        list lCarac = llGetObjectDetails(lUUID,[OBJECT_NAME,  OBJECT_ATTACHED_POINT]);
         
        integer lAttachmentType = llList2Integer(lCarac, 1);
        lReturn += lUUID; // we store the uuid of object attached to pelvis
        lReturn += llList2String(lCarac, 0); // we store the name of the object
        debug ("Attachment found : " + llList2String(lCarac, 0));
        
             
    }
    
    return lReturn;
}

// Get the location of avatar
string getLocation() {
    string lLocation;
    vector vPos=llGetPos();
    string sRegionName=llGetRegionName();
    list details = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]);
    string sParcelName = llList2String(details ,0);
    lLocation += " "+gWearerName+" is at"  + sParcelName + " http://maps.secondlife.com/secondlife/"+llEscapeURL(sRegionName)+"/"+(string)llFloor(vPos.x)+"/"+(string)llFloor (vPos.y)+"/"+(string)llFloor(vPos.z);

    return lLocation;

}

// Send the report once it is generated
sendMessage(string pMessage, list pAttachments) {
    
    // add the location
    string lLocation = getLocation();
    
    // add the message to send
    string lMessage = lLocation  +"\n\n" + pMessage;
    
    
    //add the attachments
    //lMessage = lMessage + "\n"+ "\n" + "Do you want to know what he wears? Hum? Look at this..." + "\n";
    integer n = 0;
    integer iStop = llGetListLength(pAttachments);
    string lName;
    
    for (n = 0; n < iStop; n += 2) {
        lName = llList2Key(pAttachments,n+1);
        lMessage = lMessage + lName + "\n";
    }
    
    //send the message to all owners : im or email. We checked depending on online status
    iStop = llGetListLength(gOwners);
    debug ("Number of owners * 2: " + (string) iStop);
    for (n=0; n<iStop; n += 2) {
        key owner_name_query = llRequestAgentData (llList2Key(gOwners,n), DATA_ONLINE);
        gDataOnlineRequest += (string)owner_name_query;
        gDataOnlineRequest += llList2Key(gOwners,n);
        gDataOnlineRequest += lMessage;
    }
    
}

SendMessageToOwnerIfNecessary(list pAttachments) {
    
    string lMessage;
    //2- If attachment changed then send a message to owner
    integer lLength1 = llGetListLength(gCurrentAttachments);
    integer lLength2 = llGetListLength(pAttachments);
    integer sendMessage = 0;        
    if (lLength1 != lLength2) {
        //lists size are differents so, lists are differents.
        sendMessage = 1;
    } else {
        //if list sizes are equals, we compare the items in these list
        integer iStop = llGetListLength(pAttachments);
        integer n = 0;
        integer found = 0;
        
        for (n = 0; n < iStop; n += 2) {
            string lAttachmentName = llList2String(pAttachments,n+1);
            if (llListFindList (gCurrentAttachments, (list)lAttachmentName) == -1) {
                // This item was nos previously worn in Pelvis
                found = 1;
                jump break;
            }
        }
        @break;
                    
        if (found == 1) {
            // we found an item that was not previously worn on Pelvis
            sendMessage = 1;
        }            
    }
        
    if (sendMessage == 1) {
        lMessage = "Oooooh! Look at what your Subie now wears. Do you like it or not?\n\n";
        sendMessage(lMessage, pAttachments);
        debug ("Report computation found changes");
    } else {
        debug ("Report computation found no changes");
    }
}

//this function activate the tailor app
ActivateReport() {
    gActive = 1;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"active="+(string)gActive, "");
    llSetTimerEvent(K_TIMER_DELAY);
    sendReport();
}

// tis function deactivate the tailor app
DeactivateReport() {
    gActive = 0;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"active="+(string)gActive, "");
    gCurrentAttachments=[];
    llSetTimerEvent(0);
}

sendReport() {
    debug ("Timer elapsed. Preparing report...");
    list lAttachments = getAttachments();
    debug("Attachements List : "  + (string)lAttachments);
    SendMessageToOwnerIfNecessary(lAttachments);

    // store new list of attachements
    gCurrentAttachments = lAttachments;
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth){
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

integer UserCommand(integer iAuth, string sStr, key kAv){
     
   if (iAuth < COMMAND_OWNER || iAuth > COMMAND_WEARER) return FALSE;
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));

    if (llToLower(sStr) == "menu tailor") {
        debug ("demande d'ouverture du menu tailor : " + (string)iAuth);
        list lMenuItems = [];
        string sPrompt;
        sPrompt = "\nTailor app version : " + gVersion ;
        
        if (gActive == 0) {
            if (iAuth == COMMAND_OWNER) {
                lMenuItems += [MENU_CHOICE_ACTIVATE];  
            }
            sPrompt += "\nTailor report : Deactivated";   
        } else {
            if (iAuth == COMMAND_OWNER) {
                lMenuItems += [MENU_CHOICE_DEACTIVATE]; 
            }
            sPrompt += "\nTailor report : Activated";   
        }
         if (gDebug == 0) {
             sPrompt += "\nDebug Mode : Deactivated";  
             lMenuItems += [MENU_CHOICE_DEBUG_ON]; 
        } else {
            lMenuItems += [MENU_CHOICE_DEBUG_OFF]; 
            sPrompt += "\nDebug Mode : Activated";  
        }
        sPrompt+= "\n\nhttp://lgfsite.wordpress.com";
        gkDialogID = Dialog(kAv, sPrompt, lMenuItems, [UPMENU],0, iAuth);
    }
    return TRUE;
}

default { 
    state_entry() {
        gActive = 0;
        gOwners = [];
        
        // get the name of the wearer
        gWearerName = llKey2Name(llGetOwner());
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        
        if (UserCommand(iNum, sStr, kID)){
         debug ("arrêt sur event "+ (string)iNum);
         return;
        }
        
        if (iNum == MENUNAME_REQUEST && sStr == gsParentMenu) {
            // Register Tailor menu in the Apps menu
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, gsParentMenu + "|" + gsFeatureName, "");
            debug("Registering Tailor menu in Apps Collar menu");
        } else if (iNum == LM_SETTING_RESPONSE) {
            // retrieve the owner's list
            string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) {
                gOwners = llParseString2List(sValue, [","], []);
                // pair = key, impair = nom
                debug("list of owners received :" + (string)gOwners);
                
            } else if (sGroup == gsScript) {
                // loading activity report 
                sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
                debug ("Entrée sGroup tailor pour token " + sToken);
                if(sToken == "active") {
                    debug ("Entrée sToken active");
                    if (sValue== "0") {
                        DeactivateReport();
                    } else if (sValue=="1") {
                        if (gActive == 0) {
                            ActivateReport();
                        }
                    }
                } else if (sToken == "debug") {
                    if (sValue== "0") {
                        gDebug = 0;
                    } else {
                        gDebug = 1;
                    }
                }
            }
            
            /*string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            string sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
            string sValue = llGetSubString(sStr, llSubStringIndex(sStr, "=")+1, -1);
            if (sGroup == g_sScript) {
                if(sToken == "title") g_sText = sValue;
                if(sToken == "on") g_iOn = (integer)sValue;
                if(sToken == "color") g_vColor = (vector)sValue;
                if(sToken == "height") g_vPrimScale.z = (float)sValue;
                if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
            } else if( sStr == "settings=sent") ShowHideText();*/
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == gkDialogID) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == MENU_CHOICE_ACTIVATE) {
                    ActivateReport();
                    UserCommand(iAuth, "Menu Tailor", kAv);
                } else if (sMessage == MENU_CHOICE_DEACTIVATE) {
                    DeactivateReport();
                    UserCommand(iAuth, "Menu Tailor", kAv); 
                } else if (sMessage == MENU_CHOICE_DEBUG_OFF) {
                    gDebug = 0;
                   llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"debug="+(string)gDebug, "");
                    UserCommand(iAuth, "Menu Tailor", kAv); 
                } else if (sMessage == MENU_CHOICE_DEBUG_ON) {
                    gDebug = 1;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"debug="+(string)gDebug, "");
                    UserCommand(iAuth, "Menu Tailor", kAv); 
                } else if (sMessage == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + gsParentMenu, kAv);
                } 
            }
        }
    }
    
    
    dataserver(key queryid, string data){
        
         // look for this queryid
        integer iStop = llGetListLength(gDataOnlineRequest);
        key lKAv = NULL_KEY ;
        string lMessage;
        integer n;
        for (n = 0; n < iStop; n += 3) { 
             if (queryid ==  llList2Key(gDataOnlineRequest,n)) {
                lKAv = llList2Key(gDataOnlineRequest,n+1);
                 lMessage = llList2Key(gDataOnlineRequest,n+2);
             
                 // we remove the request from the list of request
                 gDataOnlineRequest = llDeleteSubList(gDataOnlineRequest, n, n+2);
             
                 jump break;
            }
         
         }
        @break;
     
         if (lKAv != NULL_KEY) {
             // lKav contains the key on the avatar whose data is provided
             // by dataserver
             if (data == "1") {
                 llInstantMessage(lKAv, lMessage);  
                 debug (" im envoyé à " + (string)lKAv + ":" + lMessage);  
             } else {
                 //user if offline. We send an email
                llMessageLinked(LINK_SET, LM_SEND_EMAIL,(string)lKAv + "|"+ lMessage,NULL_KEY);
                 debug (" email envoyé à " + (string)lKAv + ":" + lMessage);  
             }
         }        
     }
         
    // immediately send a report
    attach(key kID) {
        if (kID) {
            //sendReport();
        }
        
    }
    
    //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
    }
    
    //if object is rezzed
    on_rez(integer param){
        //llResetScript();
    }   
    
    timer() {
        sendReport();
    }

}
