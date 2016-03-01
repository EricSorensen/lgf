////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : EMSEND
//
//  Signature                         : LGF/TBOX/COLLAR/EMSEND
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.11
//  release date                      : November 2015
//
//  Description : This component sends email. To be refactoring later
//
//  State description : Defaut is the only state used 
//
//  Messages sent by ECR (Please refer to LGF msg directory)
//
//  Message managed by Titler (Please refer to LGF msg directory)
//
//
//  documentation : http://lgfsite.wordpress.com
//
//  copyright © Lady Green Forensic 2016
//
//  This script is free software: you can redistribute it and/or modify     
//  it under the terms of the creative commons Attribution- ShareAlike 4.0 
//  International licence. (http://creativecommons.org/licenses/by-sa/4.0/legalcode)

///////////////////////////////////////////////////////////////////////////////////////////////////

integer LM_SEND_EMAIL = 3500;

string emailDest2 = "youremailproxy@blabla.com";

integer g_Debug =0;

Debug (string pStr) {
    if (g_Debug == 1 ) {
        llOwnerSay(llGetScriptName()+ ":" + pStr);
    }
}

default
{
    state_entry()
    {
       //Debug("State entry") ;
    }

    link_message(integer sender, integer cmd, string param, key id){
        // LM_SEND_EMAIL is sent by all scripts that want to send an email
        //Debug("Entrée link_message" + (string)cmd + "/" + param);
        if (cmd == LM_SEND_EMAIL ){
            list iParamsMsg = llParseString2List(param, ["|"], []);
            string iMsg = llList2String(iParamsMsg,1);
            //Debug("Message à envoyer: " + iMsg);
            llEmail (emailDest2, "A message from your Collar", iMsg);
            //Debug("Message2 émis ");
        }
    }
}
