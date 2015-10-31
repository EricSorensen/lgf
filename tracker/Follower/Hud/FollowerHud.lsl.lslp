integer CHANNEL_LGF_MASTER = - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE  = - 7515; // listen channel for register processing by LGF master object
string  MSG_BODY_BLIIP     = "BLIIP";  // BLIIP Message
string  MSG_BODY_REQ_ANS   = "REGISTER_ANSWER";  // BLIIP Message
integer INDEX_MSG_BODY     = 5;
integer INDEX_MASTER_UID   = 6;
integer INDEX_SLAVE_UID   = 6;
integer INDEX_REQ_ACTION   = 5;
string  HEADER_MASTER_FOL_HUD = "LGF|TRCK|FOLW|HUD|1.0.0.0|";
string  ACTION_REGISTER     = "REGISTER_REQUEST";
string  ACTION_SET_TITLE    = "SET_TITLE"; 
string  ACTION_UNSET_TITLE  = "UNSET_TITLE" ; 
integer CHANNEL = 15;  // That's "f" for "follow », 
integer CHANNEL_MENU = 42; // The internal Channel used with the menu
string LABEL_FOLLOWING = "Following";

list MENU_MAIN = []; // the main menu
list MENU_MAIN_REF = []; // the main menu
 
float DELAY = 0.5;   // Seconds between blinks; lower for more lag
float RANGE = 3.0;   // Meters away that we stop walking towards
float TAU = 1.0;     // Make smaller for more rushed following
 
// Avatar Follower script, by Dale Innis
// Do with this what you will, no rights reserved
// See https://wiki.secondlife.com/wiki/AvatarFollower for instructions and notes
 
float LIMIT = 60.0;   // Approximate limit (lower bound) of llMoveToTarget
 
integer lh = 0;
integer lh2= 0;
integer lh3= 0;
integer tid = 0;
string targetName = "";
key targetKey = NULL_KEY;
integer announced = FALSE;
integer initPhase = 1;
integer followerState = 0;
key titlerKey = ""; 

// logger
log (string msg) {
    //llOwnerSay (string msg);    
}


init() {
  llListenRemove(lh);
  lh = llListen(CHANNEL,"",llGetOwner(),"");
  lh2=llListen(CHANNEL_MENU, "", llGetOwner(), "");
  lh3=llListen(CHANNEL_LGF_MASTER, "", NULL_KEY, "");
  string texture = llGetInventoryName(INVENTORY_TEXTURE, 0);
  llSetTexture(texture, ALL_SIDES);
  followerState = 0;
  llSensor("", NULL_KEY, AGENT, 40.0, PI);
  SendRequestRegister();
}
 
SendRequestRegister() {
    // Blip message has to be broadcaster on master Channel
    // since the titler is designed to interact only with attached object
    // he can send message using llWhisper
    log("Send Request to register");

    llWhisper(CHANNEL_LGF_SLAVE, HEADER_MASTER_FOL_HUD + ACTION_REGISTER + "|" + (string) llGetKey ());
}

RegisterTitler(list msg ) {
    // Register Titler process
    log("registering Titler msg : " + (string)msg);
    titlerKey = (key)llList2String(msg, INDEX_SLAVE_UID);
    log("Titler registered : " + (string)titlerKey);
    
    if (followerState==1) {
        SetTitler();   
    } else {
        UnsetTitler();   
    }
}

SetTitler() {
    // send msg to titler
    log("SetTitler to : "+(string)titlerKey);

    // if a titler is attached    
    if (titlerKey){
        // send msg to titler
        log("Send Request to set Titler");

        llRegionSayTo (titlerKey, CHANNEL_LGF_SLAVE, HEADER_MASTER_FOL_HUD + ACTION_SET_TITLE +"|" + (string)llGetKey() +"|" + LABEL_FOLLOWING);
    }
}

UnsetTitler(){
    log("UnSetTitler to : "+(string)titlerKey);
    // if a titler is attached
    if (titlerKey){
        // send msg to titler
        log("Send Request to unset Titler");
        llRegionSayTo (titlerKey, CHANNEL_LGF_SLAVE, HEADER_MASTER_FOL_HUD + ACTION_UNSET_TITLE +"|" + (string)llGetKey() +"|" + "");
    }
}

  
stopFollowing() {
  llTargetRemove(tid);  
  llStopMoveToTarget();
  llSetTimerEvent(0.0);
  string texture = llGetInventoryName(INVENTORY_TEXTURE, 0);
  llSetTexture(texture, ALL_SIDES);
  UnsetTitler();
  log("No longer following.");
  followerState = 0;
}
 
startFollowingName(string name) {
  targetName = name;
  llSensor(targetName,NULL_KEY,AGENT_BY_LEGACY_NAME,96.0,PI);  // This is just to get the key
}
 
startFollowingKey(key id) {
  targetKey = id;
  followerState = 1;
  log("Now following "+targetName);
  keepFollowing();
  llSetTimerEvent(DELAY);
  string texture = llGetInventoryName(INVENTORY_TEXTURE, 1);
  llSetTexture(texture, ALL_SIDES);
  SetTitler();
}
 
keepFollowing() {
  llTargetRemove(tid);  
  llStopMoveToTarget();
  list answer = llGetObjectDetails(targetKey,[OBJECT_POS]);
  if (llGetListLength(answer)==0) {
    if (!announced) log(targetName+" seems to be out of range.  Waiting for return...");
    announced = TRUE;
  } else {
    announced = FALSE;
    vector targetPos = llList2Vector(answer,0);
    float dist = llVecDist(targetPos,llGetPos());
    if (dist>RANGE) {
      tid = llTarget(targetPos,RANGE);
      if (dist>LIMIT) {
          targetPos = llGetPos() + LIMIT * llVecNorm( targetPos - llGetPos() ) ; 
      }
      llMoveToTarget(targetPos,TAU);
    }
  }
}

string StringTruncate(string text, integer length)
{
    if (length < llStringLength(text))
        return llGetSubString(text, 0, length - 2) + "…";
 
    // else
        return text;
}
 
default {
 
  state_entry() {
    log("/"+(string)CHANNEL+" [name of person to follow] or use the menu");
    init();
  }
  
  touch_start(integer num_detected){

    log("FollowerState = "+(string)followerState);
    if (followerState == 0) {
        // we try to activate the follower
        initPhase=1;
        llSensor("", NULL_KEY, AGENT, 40.0, PI);
      } else {
        //we deactivate the follower
        stopFollowing();
      }  
}

 
  on_rez(integer x) {
    llResetScript();   // Why not?
  }
 
  listen(integer c,string n,key id,string msg) {
      
    log("Event received : " + msg + "/" + n + "/" + (string)id);
    if (c == CHANNEL) {
      // Channel Chat
       log("Channel chat");
      if (msg == "off") {
        stopFollowing();
      } else {
        startFollowingName(msg);
      }
    } else if (c==CHANNEL_MENU){
      // Channel Menu

      //Freeing menu
      MENU_MAIN = [];
      MENU_MAIN_REF =[];
      
      //lookup to find the name to follow    
      integer idx = llListFindList(MENU_MAIN, [msg]);
      startFollowingName( llList2String(MENU_MAIN_REF,idx));
   } else if (c==CHANNEL_LGF_MASTER) {
        log("Msg received on slave channel");
        // message received on the master channel
        // we parse the header of the message
        list paramsMsg = llParseString2List(msg, ["|"], []);
        // we check if the header tells us that the message come from a Titler LGF compatible
        if (llList2List(paramsMsg,0,4) == ["LGF","TBOX","DISP", "TITL", "1.0.0.0"]) {
            log("Msg received on slave channel from titler");
            
            string body = llList2String(paramsMsg, INDEX_MSG_BODY);
            
            if (body == MSG_BODY_BLIIP){
                 log("Bliip");
                SendRequestRegister();
            } else if (body == MSG_BODY_REQ_ANS) {
                log("Register Titler answer msg");
                RegisterTitler(paramsMsg);
            }
        }        
    }
  }
 
  no_sensor() {
    if (initPhase == 0){  
      log("Did not find anyone named "+targetName);
    } else {
      log("There's nobody inside 20 m to you. ");
    }
  }
 
  sensor(integer n) {
    if (initPhase==1) {
        integer i;
        string nameTrunc = "";
        key owner = llGetOwner();
        MENU_MAIN = [];
        MENU_MAIN_REF =[];
        while((i < n) && (i < 12)) {
            if (llDetectedKey(i) != owner) { 
                nameTrunc =  StringTruncate(llDetectedName(i), 20);
                MENU_MAIN += [nameTrunc]; 
                MENU_MAIN_REF += [llDetectedName(i)];
            }
            ++i;
        }       
        
        llDialog (llGetOwner(), "Select the person you want to follow :", MENU_MAIN, CHANNEL_MENU);
        initPhase = 0;
    } else {  
      startFollowingKey(llDetectedKey(0));  // Can't have two ppl with the same name, so n will be one.  Promise.  :)
    }
  }
 
  timer() {
    keepFollowing();
  }
 
  at_target(integer tnum,vector tpos,vector ourpos) {
    llTargetRemove(tnum);
    llStopMoveToTarget(); 
   }
 
} 