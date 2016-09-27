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
//  Description : This script contains the integration code with OC Cuffs
//                  
//
//  State description : 
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


string submenu = "Leash";
string parentmenu = "Main"; 

integer MSG_OC_CUFFS_MENU    = 7554;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;


default {
    state_entry() {
        // Register menu
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, submenu, NULL_KEY);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        
    }
    
    link_message(integer sender, integer num, string str, key id) {
        if (num == SUBMENU && str == submenu) {
            //someone asked for our menu
            //give this plugin's menu to id
            llMessageLinked(LINK_THIS, MSG_OC_CUFFS_MENU, "", id);
        }  else if (num == MENUNAME_REQUEST && str == parentmenu){

            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        }
    }
}
