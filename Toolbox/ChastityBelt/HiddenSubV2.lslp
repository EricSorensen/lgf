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
  
integer CHANNEL_MENU = 43;
integer LM_SEND_EMAIL = 3500; // event id to send an email
string  gLabelVisible="Your chastity belt is visible. Do you want to hide it?";
string  gLabelInvisible="Your chastity belt is invisible. Do you want to show it?";
string  gNcConfigurationName ="EcrConfig";
integer visibility =0.0;
list gCurrentAttachment;
key gOwnerFB="";
string gWearerName;
list gDataOnlineRequest;
integer gNotecardLine; // string containing on line of the configuration notecard
key gNotecardQueryId;
list MENU_MAIN = [];
integer lh=0;


integer gDebug = 1;

log (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

list getAttachments() {
    
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
        lReturn += lUUID; // we store the uuid of object attached to pelvis
        lReturn += llList2String(lCarac, 0); // we store the name of the object
        log ("Attachment found : " + llList2String(lCarac, 0));
        
             
    }
    
    return lReturn;
}

integer getBeltVisibility() {
    
    return visibility;
}

SetBeltVisibility(integer pPreviousVisibility, integer pMustShow) {
    
    if (pPreviousVisibility != pMustShow) {
        if (pMustShow==1) {
            visibility=1.0;
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
        // User changed his visibility
        // we warn the owner
        if (pNewVisibility == 0) {
            lMessage = "Hey Mistress! Do you know that the Chastity Belt of your Subie is now hidden under his clothes?";
        } else {
            lMessage = "Psssitttt... Mistress? How indecent it is! Your subie now shows his Chastity Belt to everyone!";
        }
        
        sendMessage(lMessage, pAttachments);
    
    } else {
        //2- If attachment changed then send a message to owner
        integer lLength1 = llGetListLength(gCurrentAttachment);
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
                if (llListFindList (gCurrentAttachment, (list)lAttachmentName) == -1) {
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
            if (pNewVisibility == 0) {
                lMessage = "Oooooh! Look at what your Subie now wears with his invisible chastity belt...";
            
            } else {
                lMessage = "Oooooh! Look at what your Subie now wears with his visible chastity belt...";
            }
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
    lMessage = lMessage + "\n"+ "\n" + "Do you want to know what he wears? Hum? Look at this..." + "\n";
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
    
    // we get the current visibility of the belt
    integer    lPreviousVisibility = getBeltVisibility();
    
    if (lPreviousVisibility == 1) {
        // Chastity Belt is visible
        llDialog (llGetOwner(), gLabelVisible, MENU_MAIN, CHANNEL_MENU);
    } else {
        // Chastity Belt is not visible
        llDialog (llGetOwner(), gLabelInvisible, MENU_MAIN, CHANNEL_MENU);
    
    }
    
}


doExecuteTimer() {
    integer lVisibility = getBeltVisibility();
    
    list lAttachments = getAttachments();
    log("liste des attachements : "  + (string)lAttachments);
    SendMessageToOwnerIfNecessary(lAttachments, lVisibility, lVisibility);

    // store new list of attachements
    gCurrentAttachment = lAttachments;
    
    
}


init() {
    
    // get the name of the wearer
    gWearerName = llKey2Name(llGetOwner());
 
    MENU_MAIN =[];
    MENU_MAIN =["Yes", "No"];
     
    llListenRemove(lh);
    lh=llListen(CHANNEL_MENU, "", llGetOwner(), "");    
      
    
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
        
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
        
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
                 if (data == "1") {
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
     
    listen(integer c,string n,key id,string msg) {
      
        log("Event received : " + msg + "/" + n + "/" + (string)id);
        if  (c==CHANNEL_MENU){
          // Channel Menu
    
          //Freeing menu
          MENU_MAIN = [];
          
          //lookup to find the name to follow    
          integer idx = llListFindList(MENU_MAIN, [msg]);
          integer lPreviousVisibility = 0;
          integer lNewVisibility = 0;
          if (idx==0) {
              //user accept to toggle
              if (getBeltVisibility() == 1) {
                 lPreviousVisibility=1;
                 lNewVisibility=0;
                 SetBeltVisibility(lPreviousVisibility, lNewVisibility);
              } else {
                 lPreviousVisibility=0;
                 lNewVisibility=1;
                 SetBeltVisibility(lPreviousVisibility, lNewVisibility);
              }
              list lAttachments = getAttachments();
            log("liste des attachements : "  + (string)lAttachments);
              SendMessageToOwnerIfNecessary(lAttachments, lPreviousVisibility, lNewVisibility);

            // store new list of attachements
            gCurrentAttachment = lAttachments;
    
          }   
        }
    } 
    
       changed(integer change)
   {
       if (change & CHANGED_COLOR) //vous remarquerez que l'on utilise & et non && car il s'agit d'une comparaison bit à bit.
       {
           llOwnerSay("The color or alpha changed.");
            integer i = llGetNumberOfPrims();
            integer max = llGetNumberOfSides();
            log("Nombre de sides " + (string)max);
            for (; i >= 0; --i){
                log ("Link " + (string) i + "/"  +(string)llGetLinkKey(i) + "/" + (string)llGetAlpha(i));
                
               
           }           
       }
   }    
}
