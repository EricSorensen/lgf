////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : BYOS - SOUL CATCHER
//
//  Signature                         : LGF/APPS/BYOS/SOUL-CATCHER/SOUL-CATCHER_MAIN
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : April 2019
//
//  Description : This component is the soul catcher of BYOS SYSTEM.
//                This script contains the business logic for a SOUL CATCHER compoenent
//
//
//  States description :
//      default:
//          current state when object is rezzed. Not initialized
//      running:
//          storage has been initialized. Catcher is ready to catch
//      catching:
//          catcher is currently catching a soul. One and only one soul.
//
//
//  Messages sent by SOUL_MAIN (Please refer to LGF msg directory)
//
//
//  Message managed by SOUL_MAIN (Please refer to LGF msg directory)
//
//
//  documentation : http://lgfsite.wordpress.com
//
//
//  copyright © Lady Green Forensic 2019
//
//  This script is free software: you can redistribute it and/or modify
//  it under the terms of the creative commons Attribution- ShareAlike 4.0
//  International licence. (http://creativecommons.org/licenses/by-sa/4.0/legalcode)
//
///////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////
// constants
////////////////////////////////////
string K_Version = "1.0.0.0"; // version of the component

integer K_CANAL_MASTER = 1;
integer K_CANAL_STORAGE = 2;

string K_MSG_INIT       = "INIT";
string K_MSG_INIT_ACK   = "INIT_ACK";
string K_MSG_STORE  = "STORE";
string K_MSG_DELIVER= "DELIVER";

string K_ACK_OK = "OK";
string K_ACK_NOK = "NOK";

// Bad Return codes for storage
string K_CAPACITY_FULL = "FULL_STORAGE";
string K_ALREADY_REGISTERED = "DUPLICATE_SOUL";
string K_STORAGE_EMPTY = "EMPTY_STORAGE";
string K_BAD_FORMAT = "INVALID_SOUL";

// Object name from inventory
string K_NOTECARD_INSTRUCTIONS = "BYOS instructions";
string K_OBJECT_SOUL_STEALER = "BYOS soul stealer";

////////////////////////////////////
// variables
////////////////////////////////////
integer capacity = 50;


////////////////////////////////////
// create soul ticket
////////////////////////////////////
key createTicket(key registerTicket,  key aviKey) {
  return (key)(registerTicket + "|" + (string)aviKey);
}

////////////////////////////////////
// decode soul ticket
////////////////////////////////////
list decodeTicket(key ticket){
  list returnValue = [];
  integer indexSeparator = llSubStringIndex((string)ticket,"|");

  if (indexSeparator != -1) {
    string registerTicket = llGetSubString((string)ticket, 0, indexSeparator-1);
    string aviKey = llGetSubString((string)ticket, indexSeparator+1, llStringLength(value));
    returnValue += (key)registerTicket;
    returnValue += (key)aviKey;
  }

  return returnValue;
}

////////////////////////////////////
// catch a soul
////////////////////////////////////
catchSoul(key id){
  // Generate a ticket.
  key ticket = llGenerateKey();
  string soulTicket = createTicket(ticket, id);

  //Send the request to store the ticket
  llMessageLink(LINK_THIS, K_CANAL_STORAGE, K_MSG_STORE, soulTicket);
}

////////////////////////////////////
// give instructions to a future victim
////////////////////////////////////
giveInstructions(key id){
  llGiveInventoryList(id, "BYOS", [K_NOTECARD_INSTRUCTIONS, K_OBJECT_SOUL_STEALER]);
}

////////////////////////////////////
// log function
////////////////////////////////////
debug (string pLog) {
    if (debugMode == 1) {
        llSay(DEBUG_CHANNEL,llGetScriptName()  + ":" + pLog);
    }
}


////////////////////////////////////
// default state
////////////////////////////////////
default{
  state_entry() {
    llMessageLink(LINK_THIS, K_CANAL_STORAGE, K_MSG_INIT, (key)capacity);

    }

    link_message(integer sender, integer canal, string message, key id) {
      if (canal == K_CANAL_MASTER) {
        if (message == K_MSG_INIT_ACK) {
          string returnCode = (string)id;

          if (returnCode == K_ACK_OK){
                  state running;
          } else {
            llInstantMessage(llGetOwner(), "Soul catcher storage initialization failed");
          }
        }
      }
    }
}

running {
  state_entry() {
    llInstantMessage(llGetOwner(), "Soul catcher storage initialized.");
  }

  touch_start(integer total_number) {
    integer i = 0;
    debug ("touch in running state");
    for(i=0; i < total_number; ++i) {
      giveInstructions(llDetectedKey(i));
    }
    state catching;
  }
}

catching {
  state_entry() {
    catchSoul(llGetOwner()));
  }

  // On touch give instructions
  touch_start(integer total_number) {
    integer i = 0;
    debug ("touch in running state");
    for(i=0; i < total_number; ++i) {
      giveInstructions(llDetectedKey(i));
    }
  }

  // Processing requests from parent script
  link_message(integer sender, integer canal, string message, key id) {
    if (canal == K_CANAL_MASTER) {

      // Message is for the storage Component
      if (message == K_MSG_STORE_ACK) {
        // this is an acknowledge for a store request
        debug("Acknowledge received from storage");
        string returnCode = (string) id;
        if (returnCode == K_ACK_OK) {
          // storage request OK
          debug ("Storage confirmed");

        } else {
          // storage request NOK
          debug ("Storage error: " + (string)id);
        }
        // soul processed. Return to running mode.
        state running;
      }
    }
  }

}
