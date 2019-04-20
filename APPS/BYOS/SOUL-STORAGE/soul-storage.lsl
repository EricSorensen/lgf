////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : BYOS - SOUL CATCHER
//
//  Signature                         : LGF/APPS/BYOS/SOUL-STORAGE
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : April 2019
//
//  Description : This component is the soul catcher of BYOS SYSTEM.
//                This script stores the captured souls
//
//
//  States description :
//      default:
//          current state when object is rezzed. Not initialized
//      running:
//          storage has been initialized
//
//
//  Messages sent by SOUL-STORAGE (Please refer to LGF msg directory)
//
//
//  Message managed by SOUL-STORAGE (Please refer to LGF msg directory)
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
string K_ACK_ALREADY_INITIALIZED = "ALREADY_INIT";
string K_MSG_STORE  = "STORE";
string K_MSG_STORE_ACK  = "STORE_ACK";
string K_MSG_DELIVER= "DELIVER";
string K_MSG_DELIVER_ACK  = "DELIVER_ACK";

string K_ACK_OK = "OK";
string K_ACK_NOK = "NOK";

// Bad Return codes for storage
string K_CAPACITY_FULL = "FULL_STORAGE";
string K_ALREADY_REGISTERED = "DUPLICATE_SOUL";
string K_STORAGE_EMPTY = "EMPTY_STORAGE";
string K_BAD_FORMAT = "INVALID_SOUL";

////////////////////////////////////
// variables
////////////////////////////////////
integer debugMode = 1;
list souls = [];
integer capacity = 0;


////////////////////////////////////
// log function
////////////////////////////////////
debug (string pLog) {
    if (debugMode == 1) {
        llSay(DEBUG_CHANNEL,llGetScriptName()  + ":" + pLog);
    }
}

////////////////////////////////////
// Initialize the storage capacity
////////////////////////////////////
string initialize(string value) {
  capacity = (integer)value;
  debug ("Storage initialized with a capacity of : " + (string) capacity);
  return K_ACK_OK;
}

////////////////////////////////////
// store a soul
////////////////////////////////////
string store(key value) {
  string returnCode = K_ACK_OK;
  if (llGetListLength(souls) < capacity) {
    debug ("traitement requête de stockage en cours");
    list paramTicket = llParseString2List(value, ["|"], []);
    if (llGetListLength(paramTicket)<3) {
      debug ("pas assez d'argument dans la key à stocker");
      returnCode = K_BAD_FORMAT;
    } else {
      string registerTicket = llList2String(paramTicket,0);
      string soulKey = llList2String(paramTicket,1);

      debug ("soulKey recherchée dans le storage:" + soulKey);
      string soulsList = llList2CSV(souls);
      integer index = llSubStringIndex(soulsList, soulKey);
      if (index == -1) {
        debug ("soul non trouvée dans le storage.");
        string valueToStore = registerTicket + "|" + soulKey;
        souls += valueToStore;
      } else {
        debug ("soul trouvée dans le storage.");
        returnCode = K_ALREADY_REGISTERED;
      }
    }
  } else {
    debug ("storage plein");
    returnCode = K_CAPACITY_FULL;
  }

  return returnCode;
}

////////////////////////////////////
// deliver a soul
////////////////////////////////////
string deliver() {
  string returnCode = K_ACK_NOK;
  if (llGetListLength(souls) != 0) {
    returnCode = llList2String(souls,0);
    souls = llDeleteSubList(souls,0,0);
  } else {
    returnCode = K_STORAGE_EMPTY;
  }

  return returnCode;
}

////////////////////////////////////
// default state
////////////////////////////////////
default{
  state_entry() {
    debug ("Soul storage is waiting for initialization msg");
  }

  // Processing requests from parent script
  link_message(integer sender, integer canal, string message, key id) {
    if (canal == K_CANAL_STORAGE) {
      // Message is for the storage Component
      if (message == K_MSG_INIT) {
        // this is a request to initialize the storage
        debug("Receive a request to initialize the store:" + (string)id);
        if (initialize((string)id) == K_ACK_OK) {
          // init successful
          llMessageLinked(sender, K_CANAL_MASTER, K_MSG_INIT_ACK, (key)K_ACK_OK);
          state running;
        } else {
          // do not acknowledge this initialization
          llMessageLinked(sender, K_CANAL_MASTER, K_MSG_INIT_ACK, (key)K_ACK_NOK);
        }
      }
    }

  }
}

state running {
  state_entry() {

  }

  // Processing requests from parent script
  link_message(integer sender, integer canal, string message, key id) {
    if (canal == K_CANAL_STORAGE) {

      // Message is for the storage Component
      if (message == K_MSG_STORE) {
        // this is a request to store a soul
        debug("Receive a request to store this soul:" + (string)id);
        string returnCode = store(id);
        if (returnCode == K_ACK_OK) {
          // acknowlege the request
          string msgAck = K_ACK_OK + "|" + (string)id;
          llMessageLinked(sender, K_CANAL_MASTER, K_MSG_STORE_ACK, (key)msgAck);
        } else {
          // do not acknowlege the request
          string msgAck = returnCode + "|" + (string)id;
          llMessageLinked(sender, K_CANAL_MASTER, K_MSG_STORE_ACK, (key)msgAck);
        }
      } else if (message == K_MSG_DELIVER) {
        // this is a request to deliver a soul
        debug("Receive a request to deliver a soul");
        string returnCode = deliver();
        if (returnCode != K_ACK_NOK) {
          // acknowlege the request and give the key
          llMessageLinked(sender, K_CANAL_MASTER, K_MSG_DELIVER_ACK, returnCode);
        } else {
          // do not acknowlege the request
          llMessageLinked(sender, K_CANAL_MASTER, K_MSG_STORE_ACK, (key)("|"+ K_ACK_NOK + "|" + returnCode));
        }
      } else if (message == K_MSG_INIT) {
        string msgAck = K_ACK_ALREADY_INITIALIZED + "|" + (string)capacity;
        llMessageLinked(sender, K_CANAL_MASTER, K_MSG_INIT_ACK, (key)msgAck);
      }
    }
  }
}
