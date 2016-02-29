////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : HIDSUB
//
//  Signature                         : LGF/TBOX/CHASTITY/HIDSUB
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : December 2015
//
//  Description : This component allow to hide the chastity belt when
//                    the owner is not present. Each time the sub wear a
//                    a cloth attached to pelvis, the Chastity belt is automatically
//                     hidden
//
//  State description : Defaut is the only state used 
//
//  Messages sent by HIDSUB (None)
//
//  Message managed by HIDSUB (None)
//
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////

integer LM_SEND_EMAIL = 3500; // event id to send an email
string  gNcConfigurationName ="EcrConfig";

list gCurrentAttachmentOnPelvis;
key gOwnerFB="";
string gWearerName;
list gDataOnlineRequest;
integer gNotecardLine; // string containing on line of the configuration notecard
key gNotecardQueryId;

integer gDebug = 1;

log (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

list getAttachmentOnPelvis() {
    
    // we get all attachments. 
    list lTemp = llGetAttachedList(llGetOwner());
    integer iStop = llGetListLength(lTemp);
    integer n = 0;
    
    //returned value
    list lReturn;
    
    for (n = 0; n < iStop; n += 1) {
        
        key lUUID = llList2Key(lTemp,n);
        list lCarac = llGetObjectDetails(lUUID,[OBJECT_NAME,  OBJECT_ATTACHED_POINT]);
         
        integer lAttachmentType = llList2Integer(lCarac, 1);
        
        log ("Attachment found : " + llList2String(lCarac, 0));
        
        if (lAttachmentType == ATTACH_PELVIS) {
            lReturn += lUUID; // we store the uuid of object attached to pelvis
            lReturn += llList2String(lCarac, 0); // we store the name of the object
            
            log ("Attachment found on Pelvis: " + llList2String(lCarac, 0));
        }
             
    }
    
    return lReturn;
}

integer getBeltVisibility() {
    integer lReturnValue;
    
    if (llGetAlpha(ALL_SIDES) > 0) {
        lReturnValue = 1;    
    } else {
        lReturnValue = 0;
    }
    
    return lReturnValue;
}

SetBeltVisibility(integer pPreviousVisibility, integer pMustShow) {
    
    if (pPreviousVisibility != pMustShow) {
        if (pMustShow==1) {
            llSetAlpha(1.0, ALL_SIDES);
            log("Chastity belt affiché");
        } else {
            llSetAlpha(0, ALL_SIDES);
            log("Chastity belt masqué");
        }
    }
}

string getLocation() {
    string lLocation;
    vector vPos=llGetPos();
    string sRegionName=llGetRegionName();
    list details = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]);
    string sParcelName = llList2String(details ,0);
    lLocation += " "+gWearerName+" is at"  + sParcelName + " http://maps.secondlife.com/secondlife/"+llEscapeURL(sRegionName)+"/"+(string)llFloor(vPos.x)+"/"+(string)llFloor (vPos.y)+"/"+(string)llFloor(vPos.z);

    return lLocation;

}

SendMessageToOwnerIfNecessary(list pAttachments, integer pPreviousVisibility, integer pNewVisibility) {
    
    string lMessage;
    // 1- if status changes then send a message to owner
    if (pPreviousVisibility != pNewVisibility) {
        // we warn the owner
        if (pNewVisibility == 0) {
            lMessage = "Hey Mistress! Do you know that the Chastity Belt of your Subie is now hidden under his clothes?";
        } else {
            lMessage = "Psssitttt... Mistress? How indecent it is! Your subie now show his Chastity Belt to everyone!";
        }
        
        sendMessage(lMessage, pAttachments);
    
    } else {
        //2- If attachment on pelvis changed then send a message to owner
        integer lLength1 = llGetListLength(gCurrentAttachmentOnPelvis);
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
                if (llListFindList (gCurrentAttachmentOnPelvis, (list)lAttachmentName) == -1) {
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
            lMessage = "Oooooh! Look at what your Subie now wear on his pelvis...";
            sendMessage(lMessage, pAttachments);
        }
    }
    
}

sendMessage(string pMessage, list pAttachments) {
    
    // add the location
    string lLocation = getLocation();
    
    // add the message to send
    string lMessage = lLocation  +"\n" + pMessage;
    
    
    //add the attachments
    lMessage = lMessage + "\n"+ "\n" + "Do you want to know what he wear on his Pelvis? Hum? Look at this..." + "\n";
    integer n = 0;
    integer iStop = llGetListLength(pAttachments);
    string lName;
    
    for (n = 0; n < iStop; n += 2) {
        lName = llList2Key(pAttachments,n+1);
        lMessage = lMessage + lName + "\n";
    }
    
    //send the message : im or email. We checked depending on online status
    key owner_name_query = llRequestAgentData (gOwnerFB, DATA_ONLINE);
    gDataOnlineRequest += (string)owner_name_query;
    gDataOnlineRequest += gOwnerFB;
    gDataOnlineRequest += lMessage;
    
}


doExecute() {
    
    // we get the list of all items attached to pelvis
    list lAttachments = getAttachmentOnPelvis();
    log("liste des attachements : "  + (string)lAttachments);
    integer iStop = llGetListLength(lAttachments);
    
    integer n = 0;
    integer lMustShow=1; 
    
    //Amongst each items attached to pelvis
    //we look for an item which is a clothing
    // and whose Alpha is higher than 0.95
    for (n = 0; n < iStop; n += 2) {
        key lUUID = llList2Key(lAttachments,n);
        string lName = llList2Key(lAttachments,n+1);
        
        integer lInventType = llGetInventoryType(lName);
        
        if (lInventType == INVENTORY_CLOTHING){
            // this is a clothing. We check the alpha
            // Note : currently we cannot retrieve the alpha of an external object
            // so we assume the item is visible.
            //llGetAlpha(face)
             lMustShow = 0;
            log("vêtements trouvés ");
             jump break;
        
        }
        @break;
    }    
        
    // we get the current visibility of the belt
    integer    lPreviousVisibility = getBeltVisibility();
    
    // Now we set the visibility of the belt
    SetBeltVisibility(lPreviousVisibility, lMustShow);            

    // we get the new visibility of the belt
    integer    lNewVisibility = getBeltVisibility();
            
    SendMessageToOwnerIfNecessary(lAttachments, lPreviousVisibility, lNewVisibility);
    
    // store new list of pelvis attachements
    gCurrentAttachmentOnPelvis = lAttachments;
}

init() {
    
    // get the name of the wearer
    gWearerName = llKey2Name(llGetOwner());
 
    
    // Check the notecard exists, and has been saved
    if (llGetInventoryKey(gNcConfigurationName) == NULL_KEY) {
        llOwnerSay( "Warning : ECR configuration Notecard '" + gNcConfigurationName + "' missing or unwritten");

        // Here I want to get the list of all owners to send them a message
        return;
    }
        
    // Read the notecard
    gNotecardLine = 0;
    gNotecardQueryId = llGetNotecardLine(gNcConfigurationName, gNotecardLine);
    
    // start the timer
    llSetTimerEvent(300);
} 

processConfigLine(key query_id, string data) {
    
    if (query_id == gNotecardQueryId) {
        if (data == EOF) {
            // done. Configuration processed
        } else{
            ++ gNotecardLine;
            gOwnerFB=llToLower(llStringTrim(data, STRING_TRIM));
            gNotecardQueryId = llGetNotecardLine(gNcConfigurationName, gNotecardLine);
            
        }
    } else {
        llOwnerSay( "ECR : im exceptions set for avatar : " + data);   
    }
}


default {
    state_entry() {
        init();
    }
    
    
    touch(integer num_detected) {
        string lNameToucher = llDetectedName(0);
        string lOwner = llKey2Name(llGetOwner());
        
        if (lOwner == lNameToucher) {
            llWhisper(PUBLIC_CHANNEL, lOwner + "is playing with the bird in his cage...");
        }else{
            llWhisper(PUBLIC_CHANNEL, lNameToucher + "is playing with the bird of "+ lOwner + "'s cage...");
        }
        
        doExecute();
        
        if (getBeltVisibility() == 1) {
            llWhisper(PUBLIC_CHANNEL,  "...Do you hear it singing outside his cage?");
        } else {
            llWhisper(PUBLIC_CHANNEL,  "...but the bird is a bit shy and prefers singing in the cage.");
        }
        
        
    }
    
    timer() {
        log("Réception Timer");
        doExecute();
    }
    
    dataserver(key queryid, string data){
        
        if (queryid == gNotecardQueryId) {
            processConfigLine(queryid, data);
        } else {
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
                 if (data = "1") {
                     llInstantMessage(lKAv, lMessage);  
                     log (" im envoyé à " + (string)lKAv + ":" + lMessage);  
                 } else {
                     //user if offline. We send an email
                    llMessageLinked(LINK_ALL_OTHERS, LM_SEND_EMAIL,(string)lKAv + "|"+ lMessage,NULL_KEY);
                     log (" email envoyé à " + (string)lKAv + ":" + lMessage);  
                 }
             }
        }         
     }
}
