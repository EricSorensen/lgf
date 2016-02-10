////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : ECR
//
//  Signature                         : LGF/TBOX/COLLAR/ECR
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.12
//  release date                      : 2016 January
//
//  Description : This component enforces the chat restrictions of an OpenCollar v3.9
//                  It sets the @permissive=n RLV function and add exceptions found in 
//                  a notecard of the prim inventory. Sub has to allow Mistress/Master to 
//                  edit his/her object to update this notecard
//
//  State description : Defaut is the only state used 
//
//  Messages sent by ECR : None
//
//  Message managed by ECR : None
//
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////

string  ncConfigurationName ="EcrConfig"; // name of the notecard found in the collar inventory 
                                          // and containing the script configuration
string buffer ="";
string bufferName ="";
string groupName ="";
integer notecardLine; // string containing on line of the configuration notecard
key notecardQueryId;
key groupNameRequestId;
key avatarNameRequestId;
list g_dataOnlineRequest;// LGF update
list g_dataOnlineRequestGroup;// LGF update

init() {
    g_dataOnlineRequest = [];
    g_dataOnlineRequestGroup=[];
    
    // Check the notecard exists, and has been saved
    if (llGetInventoryKey(ncConfigurationName) == NULL_KEY) {
        llOwnerSay( "Warning : ECR configuration Notecard '" + ncConfigurationName + "' missing or unwritten");

        // Here I want to get the list of all owners to send them a message
        return;
    }
        
    // Read the notecard
    notecardLine = 0;
    notecardQueryId = llGetNotecardLine(ncConfigurationName, notecardLine);
 }

processConfigLine(key query_id, string data) {
    
    if (query_id == notecardQueryId) {
        if (data == EOF) {
            // done. Configuration processed
        } else{
            // bump line number for reporting purposes and in preparation for reading next line
            if (notecardLine == 0) {
                
                // permissive line. we wait for a n or a y. so we trim and we
                // force to towercase to avoid issue
                buffer = llToLower(llStringTrim(data, STRING_TRIM));
                if ((buffer != "n") && (buffer != "y")) {
                    llOwnerSay( "Warning : ECR configuration Notecard : first line must be y or n to set @permissive RLV command");
                } else {
                    llOwnerSay( "ECR : permission set to : " + "@permissive="+buffer);
                    llOwnerSay("@permissive="+buffer);
                }
                
            } else{ 

                //we add the im exceptions
                buffer = llToLower(llStringTrim(data, STRING_TRIM));
                llOwnerSay("@startim:"+buffer+"=add");
                llOwnerSay("@sendim:"+buffer+"=add");
                llOwnerSay("@recvim:"+buffer+"=add");
                
                groupNameRequestId = llHTTPRequest("http://world.secondlife.com/group/" + buffer, [], "");
                avatarNameRequestId = llRequestAgentData( (key)buffer, DATA_NAME); 
                g_dataOnlineRequest += (string)avatarNameRequestId;
                g_dataOnlineRequestGroup += (string)groupNameRequestId;
            }
            ++notecardLine;
            notecardQueryId = llGetNotecardLine(ncConfigurationName, notecardLine);
        }
    } else {
    	 integer iStop = llGetListLength(g_dataOnlineRequest);
    	 key avatarNameRequestId = NULL_KEY ;
         integer n;
         for (n = 0; n < iStop; n += 1) { 
             if (query_id ==  llList2Key(g_dataOnlineRequest,n)) {
                 llOwnerSay( "ECR : im exceptions set for avatar : " + data);
                 
                 // we remove the request from the list of request
                 g_dataOnlineRequest = llDeleteSubList(g_dataOnlineRequest, n, n);
                 jump break;
             }
             
         }
         @break;
    }
}


default {
    state_entry() {
        init();
    }
    
     on_rez (integer startParam) {
        llResetScript();
     }
    
    dataserver(key query_id, string data) {
        
        processConfigLine(query_id, data);
    }
    
    http_response(key request_id, integer status, list metadata, string body)
    {
    	integer iStop = llGetListLength(g_dataOnlineRequestGroup);
    	
    	key groupNameRequestId = NULL_KEY ;
         integer n;
         for (n = 0; n < iStop; n += 1) { 
             if (request_id ==  llList2Key(g_dataOnlineRequestGroup,n)) {
		        list args = llParseString2List(body, ["title"], []);
		        groupName = llList2String(llParseString2List(llList2String(args, 1), [">", "<", "/"], []), 0);
		        llOwnerSay( "ECR : im exceptions set for group : " + groupName);
                 
                // we remove the request from the list of request
                g_dataOnlineRequestGroup = llDeleteSubList(g_dataOnlineRequestGroup, n, n);
                jump break;
             }
             
         }
         @break;
    	
    }
    
}
