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

string K_ACK_OK = "OK";
string K_ACK_NOK = "NOK";

//storage Management
integer capacity = 50;
integer K_CANAL_MASTER = 1;
integer K_CANAL_STORAGE = 2;
string K_MSG_INIT       = "INIT";
string K_MSG_INIT_ACK   = "INIT_ACK";
string K_ACK_ALREADY_INITIALIZED = "ALREADY_INIT";
string K_MSG_STORE  = "STORE";
string K_MSG_STORE_ACK = "STORE_ACK";
string K_MSG_DELIVER= "DELIVER";

// Bad Return codes for storage
string K_CAPACITY_FULL = "FULL_STORAGE";
string K_ALREADY_REGISTERED = "DUPLICATE_SOUL";
string K_STORAGE_EMPTY = "EMPTY_STORAGE";
string K_BAD_FORMAT = "INVALID_SOUL";

// Object name from inventory
string K_NOTECARD_INSTRUCTIONS = "BYOS instructions";
string K_OBJECT_SOUL_STEALER = "BYOS soul stealer";

// LGF messages
integer CHANNEL_LGF_MASTER         = - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE          = - 7515; // listen channel for register processing by LGF master object

string  HEADER_LGF_PROT_SOUL_CATCHER  = "LGF_MSG|LGF|BYOS|SOUL-CATCHER|SOUL-CATCHER-MAIN|1.1.0.0|"; // LGF header message sent by object
string  LGF_PROT_MSG_BLIIP            = "BLIIP"; // LGF bliip message sent by soul stealer
string  LGF_PROT_MSG_SOUL_ACK         = "SOUL_ACK";

////////////////////////////////////
// variables
////////////////////////////////////
integer debugMode = 1;
integer handleListen = 0;
key soulToSteal = NULL_KEY;

////////////////////////////////////
// create soul ticket
////////////////////////////////////
key createTicket(key registerTicket,  key aviKey) {
  return (key)((string)registerTicket + "|" + (string)aviKey);
}

////////////////////////////////////
// decode soul ticket
////////////////////////////////////
list decodeTicket(key ticket){
  list returnValue = [];
  integer indexSeparator = llSubStringIndex((string)ticket,"|");

  if (indexSeparator != -1) {
    string registerTicket = llGetSubString((string)ticket, 0, indexSeparator-1);
    string aviKey = llGetSubString((string)ticket, indexSeparator+1, llStringLength(ticket)-1);
    returnValue += (key)registerTicket;
    returnValue += (key)aviKey;
  }

  return returnValue;
}

////////////////////////////////////
// decode header and body of LGF Message
////////////////////////////////////
list decodeAndFilterLGFMessage(string message) {
  string decodedMessage;
  list paramsMsg = llParseString2List(message, ["|"], []);

  // validate the message
  if (llList2String(paramsMsg, 0) != "LGF_MSG") {
    // this is not a LGF MESSAGE
    // Ignore the message
    paramsMsg = [];
  }

  if (llList2String(paramsMsg, 2) != "BYOS") {
    // this is not a LGF MESSAGE of BYOS SYSTEM
    // Ignore the message
    paramsMsg = [];
  }

  if (llList2String(paramsMsg, 3) != "SOUL-STEALER") {
    // this is not a LGF MESSAGE of BYOS SYSTEM sent of a SOUL-STEALER
    // Ignore the message
    paramsMsg = [];
  }

  if (llGetListLength(paramsMsg)<7) {
    return paramsMsg;
  } else {
    return llList2List(paramsMsg, 6, llGetListLength(paramsMsg)-1);
  }
}

////////////////////////////////////
// catch a soul
////////////////////////////////////
catchSoul(key id){
  // Generate a ticket.
  key ticket = llGenerateKey();
  string soulTicket = createTicket(ticket, id);

  //Send the request to store the ticket
  llMessageLinked(LINK_THIS, K_CANAL_STORAGE, K_MSG_STORE, soulTicket);
}

////////////////////////////////////
// give instructions to a future victim
////////////////////////////////////
giveInstructions(key id){
  llGiveInventoryList(id, "BYOS", [K_NOTECARD_INSTRUCTIONS, K_OBJECT_SOUL_STEALER]);
}

////////////////////////////////////
// Send a storage confirmation
////////////////////////////////////
sendStealRequestAck(key soulKey, integer confirm) {
  string msg = HEADER_LGF_PROT_SOUL_CATCHER + LGF_PROT_MSG_SOUL_ACK + "|";

  if (confirm == 1) {
    msg = msg + K_ACK_OK;
  } else {
    msg = msg + K_ACK_NOK;
  }
  llRegionSayTo(soulKey, CHANNEL_LGF_MASTER, msg);
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
    string sCapacity = (string)capacity;
    llMessageLinked(LINK_THIS, K_CANAL_STORAGE, K_MSG_INIT, (key)sCapacity);
  }

  link_message(integer sender, integer canal, string message, key id) {
    if (canal == K_CANAL_MASTER) {
      if (message == K_MSG_INIT_ACK) {
        list msgAck = llParseString2List(id, ["|"], []);
        string returnCode = llList2String(msgAck, 0);

        if (returnCode == K_ACK_OK){
          state running;
        } else if (returnCode == K_ACK_ALREADY_INITIALIZED){
          debug ("Storage already initialized");
          llRegionSayTo(llGetOwner(), PUBLIC_CHANNEL, "Soul storage already initialized with a capacity of " + llList2String(msgAck, 1));
          state running;
        } else if (returnCode == K_ACK_NOK) {
            string msg = "Soul catcher storage initialization failed";
          llRegionSayTo(llGetOwner(), PUBLIC_CHANNEL, msg);
        }
      }
    }
  }
}

state running {
  state_entry() {
    llRegionSayTo(llGetOwner(), 0, "Soul catcher storage initialized. Catcher in running mode.");
    handleListen = llListen(CHANNEL_LGF_SLAVE, "","","");
  }

  touch_start(integer total_number) {
    integer i = 0;
    debug ("touch in running state");
    for(i=0; i < total_number; ++i) {
      //giveInstructions(llDetectedKey(0));
    }
  }

  // Processing requests from parent script
  link_message(integer sender, integer canal, string message, key id) {
    if (canal == K_CANAL_MASTER) {

      // Message is for the storage Component
      if (message == K_MSG_STORE_ACK) {
        // this is an acknowledge for a store request
        debug("Acknowledge received from storage");
        list msgAck = llParseString2List(id, ["|"], []);
        string returnCode = llList2String(msgAck, 0);
        if (returnCode == K_ACK_OK) {
          // storage request OK
          debug ("Storage confirmed for soul " + llList2String(msgAck, 2));
          sendStealRequestAck(llList2String(msgAck, 3), 1);
          debug ("Ack sent to " + llList2String(msgAck, 3));
        } else {
          // storage request NOK
          debug ("Storage error for soul : " + llList2String(msgAck, 2) + ". Cause =" + llList2String(msgAck, 0));
          sendStealRequestAck(llList2String(msgAck, 3), 0);
          debug ("Nack sent to " + llList2String(msgAck, 3));
        }
        // soul processed. Return to running mode.
        state running;
      }
    }
  }

  listen(integer channel, string name, key id, string message) {

    if (channel == CHANNEL_LGF_SLAVE) {
      debug ("Message reçu sur le canal esclave: " + message);
      list msg = decodeAndFilterLGFMessage(message);
      if (llGetListLength(msg) > 0){
        if (llList2String(msg,0) == LGF_PROT_MSG_BLIIP) {
          debug ("Requête de bliip reçue");
          //It's a bliip from a soul stealer
          // steal the soul
          key ownerKey = llGetOwnerKey(id);
          string ticket = createTicket(llGenerateKey(),ownerKey);
          ticket = ticket + "|" + (string)id;
          debug ("Âme en cours de vol : " + (string)ownerKey);
          debug ("Âme reçue par le stealer: " + (string)id);
          // send the soul to storage
          llMessageLinked(LINK_THIS, K_CANAL_STORAGE, K_MSG_STORE, (key)ticket);
        }
      }
    }
  }
}
