////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : FANCLUB
//
//  Signature                         : LGF/APPS/COLLAR/FANCLUB
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.10
//  release date                      : February 2016
//
//  Description : This component is an OC Apps. It allows the owner to receive a report
//                    of people who stand near the sub/slave
//
//  State description : Defaut is the only state used 
//
//  Messages sent by FANCLUB (Please refer to LGF msg directory)
//
//  Message managed by FANCLUB (Please refer to LGF msg directory)
//
//
//  documentation : http://lgfsite.wordpress.com
//
//
//  copyright © Lady Green Forensic 2016
//
//  This script is free software: you can redistribute it and/or modify     
//  it under the terms of the creative commons Attribution- ShareAlike 4.0 
//  International licence. (http://creativecommons.org/licenses/by-sa/4.0/legalcode)

///////////////////////////////////////////////////////////////////////////////////////////////////

string gVersion = "0.10"; // version of the component
string gsParentMenu = "Apps"; // Root menu fot this apps
string gsFeatureName = "Fanclub"; // Name of the menu of this apps
string gsScript= "fanclub_";     // used for parameters save
integer gActive = 1;
integer gDebug = 1;

float K_TIMER_DELAY = 60.0; // 1 min between two scan of people near the sub

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

//scan management
float K_SCAN_LENGTH = 5.0;
list gPlots;
list gPlotsName;
list gTempPlots;
integer  gLastPlotScan=0;

//black and white list management
list gWhiteList = [];
list gBlackList = [];     

//Report management
integer K_DELAY_TO_REPORT_A_PRESENCE = 300; // 60 sec/min x 5 min
integer K_DELAY_BETWEEN_TO_REPORT =  43200; //60 sec/min * 60 min/h * 12 h
integer gLastReportDate ;
string gReport;

integer LM_SEND_EMAIL = 3500; // message to send an email instead of an im

//Date conversion to string
integer DAYS_PER_YEAR        = 365;           // Non leap year
integer SECONDS_PER_YEAR     = 31536000;      // Non leap year
integer SECONDS_PER_DAY      = 86400;
integer SECONDS_PER_HOUR     = 3600;
integer SECONDS_PER_MINUTE   = 60;
integer SLT_TIMEZONE_SHIFT   = 28800;
 
list MonthNameList = [  "JAN", "FEB", "MAR", "APR", "MAY", "JUN", 
                        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC" ];
//////////////////////////////////////////////
// start  Unix2DateTimev1.0.lsl
//////////////////////////////////////////////

 
// This leap year test works for all years from 1901 to 2099 (yes, including 2000)
// Which is more than enough for UnixTime computations, which only operate over the range [1970, 2038].  (Omei Qunhua)
integer LeapYear( integer year)
{
    return !(year & 3);
}
 
integer DaysPerMonth(integer year, integer month)
{
    // Compact Days-Per-Month algorithm. Omei Qunhua.
    if (month == 2)      return 28 + LeapYear(year);
    return 30 + ( (month + (month > 7) ) & 1);           // Odd months up to July, and even months after July, have 31 days
}
 
integer DaysPerYear(integer year)
{
    return 365 + LeapYear(year);
}
 
///////////////////////////////////////////////////////////////////////////////////////
// Convert Unix time (integer) to a Date and Time string
///////////////////////////////////////////////////////////////////////////////////////
 
/////////////////////////////// Unix2DataTime() ///////////////////////////////////////
 
list Unix2DateTime(integer unixtime)
{
    // shift to SLT
    unixtime = unixtime - SLT_TIMEZONE_SHIFT;
    
    integer days_since_1_1_1970     = unixtime / SECONDS_PER_DAY;
    integer day = days_since_1_1_1970 + 1;
    integer year  = 1970;
    integer days_per_year = DaysPerYear(year);
 
    while (day > days_per_year)
    {
        day -= days_per_year;
        ++year;
        days_per_year = DaysPerYear(year);
    }
 
    integer month = 1;
    integer days_per_month = DaysPerMonth(year, month);
 
    while (day > days_per_month)
    {
        day -= days_per_month;
 
        if (++month > 12)
        {    
            ++year;
            month = 1;
        }
 
        days_per_month = DaysPerMonth(year, month);
    }
 
    integer seconds_since_midnight  = unixtime % SECONDS_PER_DAY;
    integer hour        = seconds_since_midnight / SECONDS_PER_HOUR;
    integer second      = seconds_since_midnight % SECONDS_PER_HOUR;
    integer minute      = second / SECONDS_PER_MINUTE;
    second              = second % SECONDS_PER_MINUTE;
 
    return [ year, month, day, hour, minute, second ];
}
 
///////////////////////////////// MonthName() ////////////////////////////
 
string MonthName(integer month)
{
    if (month >= 0 && month < 12)
        return llList2String(MonthNameList, month);
    else
        return "";
}
 
///////////////////////////////// DateString() ///////////////////////////
 
string DateString(list timelist)
{
    integer year       = llList2Integer(timelist,0);
    integer month      = llList2Integer(timelist,1);
    integer day        = llList2Integer(timelist,2);
 
    return (string)day + "-" + MonthName(month - 1) + "-" + (string)year;
}
 
///////////////////////////////// TimeString() ////////////////////////////
 
string TimeString(list timelist)
{
    string  hourstr     = llGetSubString ( (string) (100 + llList2Integer(timelist, 3) ), -2, -1);
    string  minutestr   = llGetSubString ( (string) (100 + llList2Integer(timelist, 4) ), -2, -1);
    string  secondstr   = llGetSubString ( (string) (100 + llList2Integer(timelist, 5) ), -2, -1);
    return  hourstr + ":" + minutestr + ":" + secondstr;
}
 
///////////////////////////////////////////////////////////////////////////////
// Convert a date and time to a Unix time integer
///////////////////////////////////////////////////////////////////////////////
 
////////////////////////// DateTime2Unix() ////////////////////////////////////
 
integer DateTime2Unix(integer year, integer month, integer day, integer hour, integer minute, integer second)
{
    integer time = 0;
    integer yr = 1970;
    integer mt = 1;
    integer days;
 
    while(yr < year)
    {
        days = DaysPerYear(yr++);
        time += days * SECONDS_PER_DAY;
    }
 
    while (mt < month)
    {
        days = DaysPerMonth(year, mt++);
        time += days * SECONDS_PER_DAY;
    }
 
    days = day - 1;
    time += days * SECONDS_PER_DAY;
    time += hour * SECONDS_PER_HOUR;
    time += minute * SECONDS_PER_MINUTE;
    time += second;
 
    return time;
}
//////////////////////////////////////////////
// End Unix2DateTimev1.0.lsl
//////////////////////////////////////////////



// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

displayPlots() {
    integer i = 0;
    integer index=-1;
    integer size = llGetListLength(gPlots);
    debug ("start of displayPlots");
    for (i=0; i<size; i=i+3) {
        key  lAv     = llList2Key(gPlots, i);
        integer startDate = llList2Integer(gPlots, i+1);
        integer endDate = llList2Integer(gPlots, i+2);
        
        debug ((string)lAv + ":" + llKey2Name(lAv) + ":" + TimeString(Unix2DateTime(startDate)) +  " to " +  TimeString(Unix2DateTime(endDate)));
        
    }
    debug ("end of displayPlots");
    
}

// This function scan the world to check which people
// are near the sub
emit() {
    //debug ("looking for plots : ");
    //we scan around the 
    llSensor("", NULL_KEY, AGENT, K_SCAN_LENGTH, PI);
}

ReportAPresenceIfNecessary(key agent, list dates) {
    // we continue the delay of presence
    integer startDate = llList2Integer(dates, 0);
    integer endDate = llList2Integer(dates, 1);
    
    if (endDate - startDate >= K_DELAY_TO_REPORT_A_PRESENCE) {
        // report the presence
        
        integer indexPlotName = llListFindList(gPlotsName, [agent]);
        string agentName = llList2String(gPlotsName, indexPlotName+1);


        string location = getLocation();
        
        string reportLine = DateString(Unix2DateTime(startDate))  + " " + TimeString(Unix2DateTime(startDate)) + " to " 
                            + DateString(Unix2DateTime(endDate))+ " " + TimeString(Unix2DateTime(endDate)) ;
        reportLine = reportLine + " " + agentName + location + "\n";
        
        gReport = gReport + reportLine;
    }

}

reportAndCleanPlots() {
    //debug ("entering ReportAndCleanPlots");

    integer i = 0;
    integer index=-1;
    integer size = llGetListLength(gPlots);
    list listToDelete = [];
    
    for (i=0; i<size; i=i+3) {
        key lAv = llList2Key(gPlots, i);
        index = llListFindList(gTempPlots,[lAv]);
        if (index < 0) {
            // we did not find lAv in gTempPlots 
            listToDelete += [lAv];
            //debug ("Avi " + llKey2Name(lAv) +  " : " + (string) lAv + " : plot deleted");
        }
    }
    
    size = llGetListLength(listToDelete);
    for (i=0; i<size; i=i+1) {
        key lAv = llList2Key(listToDelete,i);
        integer indexPlot = llListFindList(gPlots,[lAv]);
        ReportAPresenceIfNecessary(lAv, llList2List(gPlots, indexPlot+1, indexPlot+2));
        gPlots = llDeleteSubList(gPlots, indexPlot, indexPlot+2);
        
        integer indexPlotName = llListFindList(gPlotsName, [lAv]);
        gPlotsName = llDeleteSubList(gPlotsName, indexPlotName, indexPlotName+1);
        //debug ("-----delete avi "+ llKey2Name(lAv) +  " : " + (string) lAv);
        //displayPlots();
        //debug ("----- end of delete avi "+ llKey2Name(lAv) +  " : " + (string) lAv);
        
    }
}

storeScan() {
    //debug ("entering storeScan");
    integer i = 0;
    integer index=-1;
    integer size = llGetListLength(gTempPlots);
    integer indexWhiteList = 0;
    
    for (i=0; i<size; i=i+1) {
        key lAv = llList2Key(gTempPlots, i);
        indexWhiteList = llListFindList(gWhiteList, [lAv]);
        
        if (indexWhiteList < 0) {
            // Avi is not in the whitelist. So we track it
            index = llListFindList(gPlots, [lAv]);
            //debug ("index pour : " + llKey2Name(lAv) + " : " + (string)lAv + " = " + (string)index);
            if (index < 0) {
                // Plot refers a new agent. We add it
                //debug("adding a new agent :" + llKey2Name(lAv) + " : " + (string)lAv);
                gPlots += lAv;
                gPlots += [gLastPlotScan];
                gPlots += [gLastPlotScan];
                
                // We add the avi name;
                gPlotsName +=[lAv];
                gPlotsName +=[llKey2Name(lAv)];
                
            } else {
                // Plot refers to an agent we already detected
                //debug("-----updating an existing agent :" + llKey2Name(lAv) + " : " + (string)lAv);
                
                gPlots = llDeleteSubList(gPlots, index+2, index+2);
                gPlots = llListInsertList(gPlots, [gLastPlotScan], index+2);    
                
                //displayPlots();
                //debug ("----- end of updating avi "+ llKey2Name(lAv) +  " : " + (string) lAv);
                                
            }
        }
    }
    
}

// send an immediate im to owners if an intruder is detected. Just one im.
handleBlacklist() {
    //debug ("entering handleBlacklist");
    
    string lMessage = "Alert! Alert! Fanclub detected an intruder near your toy : ";
    integer i = 0;
    integer index=-1;
    integer size = llGetListLength(gTempPlots);
    integer indexBlackList = 0;
    
    for (i=0; i<size; i=i+1) {
        key lAvPlot = llList2Key(gTempPlots, i);
        indexBlackList = llListFindList(gBlackList, [lAvPlot]);        
        
        if (indexBlackList >= 0) {
            // Avi is in the blacklist. So we send an im to owners
            //send the message to all owners : im 
            //TODO : deal with gPlots. If starttime == endtime then send an im
            
            integer iStop = llGetListLength(gOwners);
            integer n = 0;
            string lMessageIntruder = lMessage + llKey2Name(lAvPlot);
            
            for (n=0; n<iStop; n += 2) {
                key lKAv = llList2Key(gOwners,n);
                // We send an im
                llInstantMessage(lKAv, lMessageIntruder);
            }
        }
    }    
}

senReportIfNecessary() {
    //debug ("entering senReportIfNecessary");
    
    integer currentTime = llGetUnixTime();

    if ((currentTime - gLastReportDate) >= K_DELAY_BETWEEN_TO_REPORT) {
        sendReport();        
    } 
}

cleanScanCycle() {
	gTempPlots = [];
}

managePlots() {
    //first, we clean the list of non-detected plots
    reportAndCleanPlots();
    
    //now we store the last detected plots.
    storeScan();
    
    //manage blacklist
    handleBlacklist();
        
    //now we have to check if we must send a report
    senReportIfNecessary();
    
    // clean scan cycle
    cleanScanCycle();
    
    
    //debug ("dump of gTempPlots : " + (string) gTempPlots);
    displayPlots();
    debug ("dump of report : " + gReport);
}


// Get the location of avatar
string getLocation() {
    string lLocation;
    vector vPos=llGetPos();
    string sRegionName=llGetRegionName();
    list details = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]);
    string sParcelName = llList2String(details ,0);
    lLocation += " at "  + sParcelName + " http://maps.secondlife.com/secondlife/"+llEscapeURL(sRegionName)+"/"+(string)llFloor(vPos.x)+"/"+(string)llFloor (vPos.y)+"/"+(string)llFloor(vPos.z);

    return lLocation;

}

// Send the report once it is generated
sendReport() {
    
    // add the message to send
    string lMessage = "My Divine Goddess, here's is your fanclub report which tells you who wandered near your toy. Please note that all time are given in SLT Timezone."  +"\n\n";
    
    
    lMessage = lMessage + gReport;
    
    //send the message to all owners : im 
    integer iStop = llGetListLength(gOwners);
    integer n=0;
    for (n=0; n<iStop; n += 2) {
        key lKAv = llList2Key(gOwners,n);
        // We send an email
        llMessageLinked(LINK_ALL_OTHERS, LM_SEND_EMAIL,(string)lKAv + "|"+ lMessage,NULL_KEY);
    }
    
}

//this function activate the fanclub app
ActivateReport() {
    gActive = 1;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"active="+(string)gActive, "");
    llSetTimerEvent(K_TIMER_DELAY);
    sendReport();
}

// tis function deactivate the fanclub app
DeactivateReport() {
    gActive = 0;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"active="+(string)gActive, "");
    gReport="";
    llSetTimerEvent(0);
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

    if (llToLower(sStr) == "menu fanclub") {
        //debug ("demande d'ouverture du menu fanclub : " + (string)iAuth);
        list lMenuItems = [];
        string sPrompt;
        sPrompt = "\nFanclub app version : " + gVersion ;
        
        if (gActive == 0) {
            if (iAuth == COMMAND_OWNER) {
                lMenuItems += [MENU_CHOICE_ACTIVATE];  
            }
            sPrompt += "\nFanclub report : Deactivated";   
        } else {
            if (iAuth == COMMAND_OWNER) {
                lMenuItems += [MENU_CHOICE_DEACTIVATE]; 
            }
            sPrompt += "\nFanclub report : Activated";   
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
        ActivateReport();
        gOwners = [];
        gPlots =[];
        gPlotsName=[];
        gLastPlotScan = 0;
        gReport = "";
        gLastReportDate = llGetUnixTime();
        gWhiteList = [];
        gBlackList =[];
        
        // get the name of the wearer
        gWearerName = llKey2Name(llGetOwner());
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        
  
        if (UserCommand(iNum, sStr, kID)){
         return;
        }
        

        
        if (iNum == MENUNAME_REQUEST && sStr == gsParentMenu) {
            // Register Fanclub menu in the Apps menu
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, gsParentMenu + "|" + gsFeatureName, "");
            //debug("Registering Fanclub menu in Apps Collar menu");
        } else if (iNum == LM_SETTING_RESPONSE) {
            // retrieve the owner's list
            string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) {
                gOwners = llParseString2List(sValue, [","], []);
                // pair = key, impair = nom
                //debug("list of owners received :" + (string)gOwners);
                
            } else if (sGroup == gsScript) {
                // loading activity report 
                sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
                //debug ("Entrée sGroup fanclub pour token " + sToken);
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
            
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == gkDialogID) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == MENU_CHOICE_ACTIVATE) {
                    ActivateReport();
                    UserCommand(iAuth, "Menu Fanclub", kAv);
                } else if (sMessage == MENU_CHOICE_DEACTIVATE) {
                    DeactivateReport();
                    UserCommand(iAuth, "Menu Fanclub", kAv); 
                } else if (sMessage == MENU_CHOICE_DEBUG_OFF) {
                    gDebug = 0;
                   llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"debug="+(string)gDebug, "");
                    UserCommand(iAuth, "Menu Fanclub", kAv); 
                } else if (sMessage == MENU_CHOICE_DEBUG_ON) {
                    gDebug = 1;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, gsScript+"debug="+(string)gDebug, "");
                    UserCommand(iAuth, "Menu Fanclubƒ", kAv); 
                } else if (sMessage == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + gsParentMenu, kAv);
                } 
            }
        }
    }
    
             
    // immediately send a report
    attach(key kID) {
        if (kID) {
            sendReport();
        }
        
    }
    
    //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            llResetScript();
        }
    }
    
    //if object is rezzed
    on_rez(integer param){
        //llResetScript();
    }   
    
    timer() {
        emit();
    }
  
      // Fill the detected plots to the list of plots to handle
    sensor(integer n) {
        
        debug((string)n + " plots detected");
        // store the time of this scan
        gLastPlotScan = llGetUnixTime();
        
        integer i;
        gTempPlots=[];
        while(i < n) {
            gTempPlots +=[llDetectedKey(i)];
            ++i;
        }
        managePlots();       
    }
    

}



