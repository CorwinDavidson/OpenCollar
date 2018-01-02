// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Garvin Twine, Cleo Collins,  
// Satomi Ahn, Master Starship, Sei Lisa, Joy Stipe, Wendy Starfall,    
// Medea Destiny, littlemousy, Romka Swallowtail, Sumi Perl et al.     
// Licensed under the GPLv2. See LICENSE for full details. 



string g_sWearerID;
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

string g_sDrop = "f364b699-fb35-1640-d40b-ba59bdd5f7b7";

integer OWNER_LIST = 1;
integer TRUST_LIST = 2;
integer BLOCK_LIST = 3;

integer LINK_AUTH;

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_BLOCKED = 520;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
integer LOADPIN = -1904;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;
//integer FIND_AGENT = -9005;

//added for attachment auth (garvin)
integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
string UPMENU = "BACK";

integer g_iOwnSelf; // self-owned wearers
string g_sFlavor = "OwnSelf";

list g_lMenuIDs;
integer g_iMenuStride = 3;

//key REQUEST_KEY;
integer g_iFirstRun;

string g_sSettingToken = "auth_";
//string g_sGlobalToken = "global_";

/*integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

string NameURI(string sID){
    return "secondlife:///app/agent/"+sID+"/about";
}

Dialog(string sID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, integer iSensor) {
    key kMenuID = llGenerateKey();
    if (iSensor)
        llMessageLinked(LINK_DIALOG, SENSORDIALOG, sID +"|"+sPrompt+"|0|``"+(string)AGENT+"`10`"+(string)PI+"`"+llList2String(lChoices,0)+"|"+llDumpList2String(lUtilityButtons, "`")+"|" + (string)iAuth, kMenuID);
    else
        llMessageLinked(LINK_DIALOG, DIALOG, sID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [sID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [sID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [sID, kMenuID, sName];
    }
}

AuthMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[Access & Authorization]";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "− Owner", "− Trust", "− Block"];

    if ( getGlobalVariable("kGroup") == "") lButtons += ["Group ☐"];    //set group
    else lButtons += ["Group ☑"];    //unset group
    if ((integer)getGlobalVariable("iOpenAccess")) lButtons += ["Public ☑"];    //set open access
    else lButtons += ["Public ☐"];    //unset open access
    if (g_iOwnSelf) lButtons += g_sFlavor+" ☑";    //add wearer as owner
    else lButtons += g_sFlavor+" ☐";    //remove wearer as owner

    lButtons += ["Runaway","Access List"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Auth",FALSE);
}

RemPersonMenu(key kID, string sToken, integer iAuth) {
    list lPeople;
    if (sToken=="owner") lPeople = llJson2List(llJsonGetValue(getAuthList(OWNER_LIST),[sToken]));
    else if (sToken=="trust") lPeople = llJson2List(llJsonGetValue(getAuthList(TRUST_LIST),[sToken]));
    else if (sToken=="block") lPeople = llJson2List(llJsonGetValue(getAuthList(BLOCK_LIST),[sToken]));
    else return;
    if (llGetListLength(lPeople)){
        string sPrompt = "\nChoose the person to remove:\n";
        list lButtons;
        integer iNum= llGetListLength(lPeople);
        integer n;
        for(;n<iNum;n=n+1) {
            string sName = llList2String(lPeople,n);
            if (sName) lButtons += [sName];
        }
        Dialog(kID, sPrompt, lButtons, ["Remove All",UPMENU], -1, iAuth, "remove"+sToken, FALSE);
    } else {
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The list is empty",kID);
        AuthMenu(kID, iAuth);
    }
}

OwnSelfOff(key kID) {
    g_iOwnSelf = FALSE;
    if (kID == g_sWearerID)
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nYou no longer own yourself.\n",kID);
    else
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% does no longer own themselves.\n",kID);
}

RemovePerson(string sPersonID, string sToken, key kCmdr, integer iPromoted) {
    string kTempOwner = getGlobalVariable("kTempOwner");
    if (!~llListFindList(["tempowner","owner","trust","block"],[sToken])) return;
// ~ is bitwise NOT which is used for the llListFindList function to simply turn the result "-1" for "not found" into a 0 (FALSE)
    
    if ((kTempOwner == (string)kCmdr) && ! hasAuth(OWNER_LIST,(string)kCmdr) && sToken != "tempowner"){
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kCmdr);
        return;
    }
    integer iFound;
    integer iListID = llListFindList(["tempowner","owner","trust","block"],[sToken]);
    if (sToken=="tempowner") {
        if ((kTempOwner == sPersonID) || (llToLower(sPersonID) == "remove all")) setGlobalVariable("kTempOwner", "");
    }
    else {
        if (hasAuth(iListID, sPersonID)) {
            if (sToken == "owner" && sPersonID == g_sWearerID) OwnSelfOff(kCmdr);
            modifyAuthList(iListID,sPersonID,"0");
            if (!iPromoted) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(sPersonID)+" removed from " + sToken + " list.",kCmdr);
            iFound = TRUE;            
        }
        else if (llToLower(sPersonID) == "remove all") {
            if (sToken == "owner" && hasAuth(iListID,g_sWearerID)) OwnSelfOff(kCmdr);
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+sToken+" list cleared.",kCmdr);
            modifyAuthList(iListID,"","-1");
            iFound = TRUE;            
        }
    }

    if (iFound){
        if ( llJsonGetValue(getAuthList(iListID),[sToken]) != "")
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llJsonGetValue(getAuthList(iListID),[sToken]), "");
        else
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + sToken, "");
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llJsonGetValue(getAuthList(iListID),[sToken]), "");
        //store temp list*/
        if (sToken=="owner") { 
            if (llJsonGetValue(getAuthList(iListID),[sToken]) != "") SayOwners();
        }  
    } else
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\""+NameURI(sPersonID) + "\" is not in "+sToken+" list.",kCmdr);
}

AddUniquePerson(string sPersonID, string sToken, key kID) {
    string kTempOwner = getGlobalVariable("kTempOwner");
    integer isOwner = FALSE;
    integer isTrusted = FALSE;
    integer isBlocked = FALSE;

    //Debug(NameURI(kID)+" is adding "+NameURI(sPersonID)+" to list "+sToken);
    if ((kTempOwner == (string)kID) && ! hasAuth(OWNER_LIST,(string)kID) && sToken != "tempowner")    
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    else {
        integer iListID = llListFindList(["tempowner","owner","trust","block"],[sToken]); 
        if (~llListFindList(["owner","trust","block"],[sToken])) 
        {       
            isOwner = hasAuth(OWNER_LIST,sPersonID);
            isTrusted = hasAuth(TRUST_LIST,sPersonID);
            isBlocked = hasAuth(BLOCK_LIST,sPersonID);
        
            if (sToken=="trust") {
                if (isOwner) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" is already Owner! You should really trust them.\n",kID);
                    return;
                } else if (sPersonID==g_sWearerID) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" doesn't belong on this list as the wearer of the %DEVICETYPE%. Instead try: /%CHANNEL% %PREFIX% ownself on\n",kID);
                    return;
                }
            } else if (sToken=="block") {
                if (isTrusted) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\nYou trust "+NameURI(sPersonID)+". If you really want to block "+NameURI(sPersonID)+" then you should remove them as trusted first.\n",kID);
                    return;
                } else if (isOwner) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" is Owner! Remove them as owner before you block them.\n",kID);
                    return;
                }
            }                
        } else if (sToken=="tempowner") {
            if (kTempOwner != "") {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry!\n\nYou can only be captured by one person at a time.\n",kID);
                return;
            }
            else {
                if (sToken=="tempowner") setGlobalVariable("kTempOwner",sPersonID);
            }
        } else return;

        if (! hasAuth(iListID,sPersonID)) { //owner is not already in list.  add him/her
            modifyAuthList(iListID,sPersonID,"1");
            if (sPersonID == g_sWearerID && sToken == "owner") g_iOwnSelf = TRUE;
        } else {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(sPersonID)+" is already registered as "+sToken+".",kID);
            return;
        }
        if (sPersonID != g_sWearerID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Building relationship...",g_sWearerID);
        if (sToken == "owner") {
            if (hasAuth(TRUST_LIST,sPersonID)) RemovePerson(sPersonID, "trust", kID, TRUE);
            if (hasAuth(BLOCK_LIST,sPersonID)) RemovePerson(sPersonID, "block", kID, TRUE);
            llPlaySound(g_sDrop,1.0);
        } else if (sToken == "trust") {
            if (hasAuth(BLOCK_LIST,sPersonID)) RemovePerson(sPersonID, "block", kID, TRUE);
            if (sPersonID != g_sWearerID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Looks like "+NameURI(sPersonID)+" is someone you can trust!",g_sWearerID);
            llPlaySound(g_sDrop,1.0);
        }
        if (sToken == "owner") {
            if (sPersonID == g_sWearerID) {
                if (kID == g_sWearerID)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nCongratulations, you own yourself now.\n",g_sWearerID);
                else
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% is their own Owner now.\n",kID);
            } else
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% belongs to you now.\n\nSee [https://github.com/OpenCollarTeam/OpenCollar/wiki/Access here] what that means!\n",sPersonID);
        }
        if (sToken == "trust")
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% seems to trust you.\n\nSee [https://github.com/OpenCollarTeam/OpenCollar/wiki/Access here] what that means!\n",sPersonID);
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llJsonGetValue(getAuthList(iListID),[sToken]), "");
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llJsonGetValue(getAuthList(iListID),[sToken]), "");
        if (sToken=="owner") { 
            if (llJsonGetValue(getAuthList(iListID),[sToken]) != "" || sPersonID != g_sWearerID) SayOwners();
        }                
    }
}

SayOwners() {  // Give a "you are owned by" message, nicely formatted.
    list lTemp = llJson2List(llJsonGetValue(getAuthList(OWNER_LIST),["owner"]));
    integer iCount = llGetListLength(lTemp);

    if (iCount) {
        integer index = llListFindList(lTemp, [g_sWearerID]);
        //if wearer is also owner, move the key to the end of the list.
        if (~index) lTemp = llDeleteSubList(lTemp,index,index) + [g_sWearerID];
        string sMsg = "You belong to ";
        if (iCount == 1) {
            if (llList2Key(lTemp,0)==g_sWearerID)
                sMsg += "yourself.";
            else
                sMsg += NameURI(llList2String(lTemp,0))+".";
        } else if (iCount == 2) {
            sMsg +=  NameURI(llList2String(lTemp,0))+" and ";
            if (llList2String(lTemp,1)==g_sWearerID)
                sMsg += "yourself.";
            else
                sMsg += NameURI(llList2Key(lTemp,1))+".";
        } else {
            index=0;
            do {
                sMsg += NameURI(llList2String(lTemp,index))+", ";
                index+=1;
            } while (index<iCount-1 && index < 9 );
            if (iCount > 10) {
                sMsg += NameURI(llList2String(lTemp,index))+" et al.";
                if (llList2String(lTemp,index) == g_sWearerID)
                    sMsg += " and yourself.";
            }
            else {
                if (llList2String(lTemp,index) == g_sWearerID)
                    sMsg += "and yourself.";
                else
                    sMsg += "and "+NameURI(llList2String(lTemp,index))+".";     
            }
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMsg,g_sWearerID);
 //       Debug("Lists Loaded!");
    }
}

integer in_range(key kID) {
    if ((integer)getGlobalVariable("iLimitRange")) {
        if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) > 20) //if the distance between my position and their position  > 20
            return FALSE;
    }
    return TRUE;
}

integer Auth(string sObjID) {
    string sID = (string)llGetOwnerKey(sObjID); // if sObjID is an avatar key, then sID is the same key
    integer iNum;
         
    if (hasAuth(OWNER_LIST,sID) || getGlobalVariable("kTempOwner") == sID)
        iNum = CMD_OWNER;
    else if ((llJsonGetValue(getAuthList(OWNER_LIST),["owner"]) == "" && getGlobalVariable("kTempOwner") == "") && sID == g_sWearerID)
        //if no owners set, then wearer's cmds have owner auth
        iNum = CMD_OWNER;
    else if (hasAuth(BLOCK_LIST,sID))
        iNum = CMD_BLOCKED;
    else if (hasAuth(TRUST_LIST,sID))
        iNum = CMD_TRUSTED;
    else if (sID == g_sWearerID)
        iNum = CMD_WEARER;
    else if ((integer)getGlobalVariable("iOpenAccess"))
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    else if ((integer)getGlobalVariable("iGroupEnabled") && (string)llGetObjectDetails((key)sObjID, [OBJECT_GROUP]) == getGlobalVariable("kGroup") && (key)sID != g_sWearerID)  //meaning that the command came from an object set to our control group, and is not owned by the wearer
        iNum = CMD_GROUP;
    else if (llSameGroup(sID) && (integer)getGlobalVariable("iGroupEnabled") && sID != g_sWearerID) {
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    } else
        iNum = CMD_EVERYONE;
    //Debug("Authed as "+(string)iNum);
    return iNum;
}

UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
   // Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    string sMessage = llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    if (sStr == "menu "+g_sSubMenu) AuthMenu(kID, iNum);
    else if (sStr == "list") {   //say owner, secowners, group
        if (iNum == CMD_OWNER || kID == g_sWearerID) {
            //Do Owners list
            list lTemp = llJson2List(llJsonGetValue(getAuthList(OWNER_LIST),["owner"]));
            integer iLength = llGetListLength(lTemp);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(lTemp, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Owners: "+sOutput,kID);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Owners: none",kID);
            if (getGlobalVariable("kTempOwner") != "") iLength = 1;
            else iLength = 0;
            sOutput="";
            if (iLength)
                sOutput += "\n" + NameURI(getGlobalVariable("kTempOwner"));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Temporary Owner: "+sOutput,kID);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Temporary: none",kID);  
            lTemp = llJson2List(llJsonGetValue(getAuthList(TRUST_LIST),["trust"]));          
            iLength = llGetListLength(lTemp);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(lTemp, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Trusted: "+sOutput,kID);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Trusted: none",kID);            
            lTemp = llJson2List(llJsonGetValue(getAuthList(BLOCK_LIST),["block"]));   
            iLength = llGetListLength(lTemp);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(lTemp, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Blocked: "+sOutput,kID);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Blocked: none",kID);            
            //if (g_sGroupName) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group: "+g_sGroupName,kID);
            if (getGlobalVariable("kGroup")) 
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group: secondlife:///app/group/"+getGlobalVariable("kGroup")+"/about",kID);
            sOutput="closed";
            if ((integer)getGlobalVariable("iOpenAccess")) sOutput="open";
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Public Access: "+ sOutput,kID);
        }
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%1",kID);
        if (iRemenu) AuthMenu(kID, iNum);
    } else if (sCommand == "ownself" || sCommand == llToLower(g_sFlavor)) {
        if (iNum == CMD_OWNER && !(getGlobalVariable("kTempOwner") == (string)kID)) {
            if (sAction == "on") {
                //g_iOwnSelf = TRUE;
                UserCommand(iNum, "add owner " + g_sWearerID, kID, FALSE);
            } else if (sAction == "off") {
                g_iOwnSelf = FALSE;
                UserCommand(iNum, "rm owner " + g_sWearerID, kID, FALSE);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%2", kID);
         if (iRemenu) AuthMenu(kID, iNum);
    } else if (sMessage == "owners" || sMessage == "access") {   //give owner menu
        AuthMenu(kID, iNum);
    } else if (sCommand == "owner" && iRemenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sCommand == "add") { //add a person to a list
        if (!~llListFindList(["owner","trust","block"],[sAction])) return; //not a valid command
        string sTmpID = llList2String(lParams,2); //get full name
        if (iNum!=CMD_OWNER && !( sAction == "trust" && kID==g_sWearerID )) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%3",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID));
        } else if ((key)sTmpID){
            AddUniquePerson(sTmpID, sAction, kID);
            if (iRemenu) Dialog(kID, "\nChoose who to add to the "+sAction+" list:\n",[sTmpID],[UPMENU],0,Auth(kID),"AddAvi"+sAction, TRUE);
        } else
            Dialog(kID, "\nChoose who to add to the "+sAction+" list:\n",[sTmpID],[UPMENU],0,iNum,"AddAvi"+sAction, TRUE);
    } else if (sCommand == "remove" || sCommand == "rm") { //remove person from a list
        if (!~llListFindList(["owner","trust","block"],[sAction])) return; //not a valid command
        string sTmpID = llDumpList2String(llDeleteSubList(lParams,0,1), " "); //get full name
        if (iNum != CMD_OWNER && !( sAction == "trust" && kID == g_sWearerID )) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%4",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID));
        } else if ((key)sTmpID) {
            RemovePerson(sTmpID, sAction, kID, FALSE);
            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID));
        } else if (llToLower(sTmpID) == "remove all") {
            RemovePerson(sTmpID, sAction, kID, FALSE);
            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID));
        } else RemPersonMenu(kID, sAction, iNum);
     } else if (sCommand == "group") {
         if (iNum==CMD_OWNER){
             if (sAction == "on") {
                //if key provided use that, else read current group
                if ((key)(llList2String(lParams, -1))) setGlobalVariable("kGroup",(string)llList2String(lParams, -1));
                else setGlobalVariable("kGroup",llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0)); //record current group key
    
                if (getGlobalVariable("kGroup") != "") {
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "group=" + getGlobalVariable("kGroup"), "");
                    setGlobalVariable("iGroupEnabled","1");
                    llMessageLinked(LINK_RLV, RLV_CMD, "setgroup=n", "auth");
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Group set to secondlife:///app/group/" + getGlobalVariable("kGroup") + "/about\n\nNOTE: If RLV is enabled, the group slot has been locked and group mode has to be disabled before %WEARERNAME% can switch to another group again.\n",kID);
                }
            } else if (sAction == "off") {
                setGlobalVariable("kGroup","");
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "group", "");
                setGlobalVariable("iGroupEnabled","0");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Group unset.",kID);
                llMessageLinked(LINK_RLV, RLV_CMD, "setgroup=y", "auth");
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%5",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sCommand == "public") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                setGlobalVariable("iOpenAccess","1");
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "public=" + getGlobalVariable("iOpenAccess"), "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The %DEVICETYPE% is open to the public.",kID);
            } else if (sAction == "off") {
                setGlobalVariable("iOpenAccess","0");
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "public", "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The %DEVICETYPE% is closed to the public.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%6",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sCommand == "limitrange") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                setGlobalVariable("iLimitRange","1");
                // as the default is range limit on, we do not need to store anything for this
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "limitrange", "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Public access range is limited.",kID);
            } else if (sAction == "off") {
                setGlobalVariable("iLimitRange","0");
                // save off state for limited range (default is on)
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "limitrange=" + getGlobalVariable("iLimitRange"), "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Public access range is simwide.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%7",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sMessage == "runaway"){
       // list lButtons=[];
      // string message;//="\nOnly the wearer or an Owner can access this menu";
        if (kID == g_sWearerID){  //wearer called for menu
            if (g_iRunawayDisable)
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%8",kID);
            else {
                Dialog(kID, "\nDo you really want to run away from all owners?", ["Yes", "No"], [UPMENU], 0, iNum, "runawayMenu",FALSE);
                return;
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"This feature is only for the wearer of the %DEVICETYPE%.",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sCommand == "flavor") {
        if (kID != g_sWearerID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%9",kID);
        else if (sAction) {
            g_sFlavor = llGetSubString(sStr,7,15);
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nYour new flavor is \""+g_sFlavor+"\".\n",kID);
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"flavor="+g_sFlavor,"");
        } else 
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nYour current flavor is \""+g_sFlavor+"\".\n\nTo set a new flavor type \"/%CHANNEL% %PREFIX% flavor MyFlavor\". Flavors must be single names and can only be a maximum of 9 characters.\n",kID);
    }
}

RunAway() {
    llMessageLinked(LINK_DIALOG,NOTIFY_OWNERS,"%WEARERNAME% ran away!","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + "owner=", "");
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "owner", "");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + "tempowner=", "");    
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "tempowner", "");
    // moved reset request from settings to here to allow noticifation of owners.
    llMessageLinked(LINK_ALL_OTHERS, CMD_OWNER, "clear", g_sWearerID);
    llMessageLinked(LINK_ALL_OTHERS, CMD_OWNER, "runaway", g_sWearerID); // this is not a LM loop, since it is now really authed
    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway finished.",g_sWearerID);
    llResetScript();
}


modifyAuthList(integer iList, string kID, string iAction)
{
    string sAuthToken;
    if (iList == OWNER_LIST) sAuthToken = "owner";
    else if (iList == TRUST_LIST) sAuthToken = "trust";
    else if (iList == BLOCK_LIST) sAuthToken = "block";
    string sAuthJSON = (string)llGetLinkMedia(LINK_AUTH,iList,[PRIM_MEDIA_HOME_URL]) + (string)llGetLinkMedia(LINK_THIS,iList,[PRIM_MEDIA_WHITELIST]);

    if (iAction == "1") {
        sAuthJSON = llJsonSetValue(sAuthJSON,[sAuthToken,JSON_APPEND],kID);
    }
    else if (iAction == "-1")
    {
        sAuthJSON = llJsonSetValue(sAuthJSON,[sAuthToken],"");
    }
    else {
        sAuthJSON = strReplace(sAuthJSON, "\"" + kID + "\"", "");
        sAuthJSON = strReplace(sAuthJSON, ",,", ",");        
    }
    
    integer iMax = llStringLength(sAuthJSON);
    
    if (iMax > 1024)
    {
         llSetLinkMedia(LINK_AUTH,iList,[PRIM_MEDIA_HOME_URL,llGetSubString(sAuthJSON,0,1023),PRIM_MEDIA_WHITELIST,llGetSubString(sAuthJSON,1024,iMax),PRIM_MEDIA_PERMS_CONTROL,PRIM_MEDIA_PERM_NONE,PRIM_MEDIA_PERMS_INTERACT,PRIM_MEDIA_PERM_NONE]);
    }
    else if (iMax <= 1024)
    {
        llSetLinkMedia(LINK_AUTH,iList,[PRIM_MEDIA_HOME_URL,sAuthJSON,PRIM_MEDIA_WHITELIST,"",PRIM_MEDIA_PERMS_CONTROL,PRIM_MEDIA_PERM_NONE,PRIM_MEDIA_PERMS_INTERACT,PRIM_MEDIA_PERM_NONE]);
    }
}

string getAuthList(integer iList)
{
    return (string)llGetLinkMedia(LINK_AUTH,iList,[PRIM_MEDIA_HOME_URL]) + (string)llGetLinkMedia(LINK_AUTH,iList,[PRIM_MEDIA_WHITELIST]);
}

string strReplace(string str, string search, string replace) {
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

integer hasAuth(integer iList, string kID)
{
    return ~llSubStringIndex((string)llGetLinkMedia(LINK_AUTH,iList,[PRIM_MEDIA_HOME_URL]) + (string)llGetLinkMedia(LINK_THIS,iList,[PRIM_MEDIA_WHITELIST]), kID);
}

setGlobalVariable(string gVariable, string gValue)
{
    llSetLinkMedia(LINK_AUTH,0,[PRIM_MEDIA_HOME_URL, llJsonSetValue((string)llGetLinkMedia(LINK_AUTH,0,[PRIM_MEDIA_HOME_URL]), [gVariable], gValue)]);
}

string getGlobalVariable(string gVariable)
{
    return llJsonGetValue((string)llGetLinkMedia(LINK_AUTH,0,[PRIM_MEDIA_HOME_URL]), [gVariable]);
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        integer n;
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        else g_iFirstRun = TRUE;
      /*  if (g_iProfiled){
            llScriptProfiler(1);
           // Debug("profiling restarted");
        }*/
        //llSetMemoryLimit(65536);
        g_sWearerID = llGetOwner();
        llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_REQUEST","");
        LINK_AUTH = llGetLinkNumber();

        setGlobalVariable("kTempOwner","");
        setGlobalVariable("kGroup","");        
        modifyAuthList(OWNER_LIST,"","-1");
        modifyAuthList(TRUST_LIST,"","-1");
        modifyAuthList(BLOCK_LIST,"","-1");
            }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
        //llSetTimerEvent(0.22);
        integer iAuth = Auth(kID);
        if ( kID == g_sWearerID && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
            if (g_iRunawayDisable)
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway is currently disabled.",g_sWearerID);
            else
                UserCommand(iAuth,"runaway",kID, FALSE);
        } else if (iAuth == CMD_OWNER && sStr == "runaway")
            UserCommand(iAuth, "runaway", kID, FALSE);

         if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
            UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            //Debug("Got setting response: "+sStr);
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            lParams = [];
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "owner") {
                    //setAuthList(OWNER_LIST, llParseString2List(sValue, [","], []));
                    if (~llSubStringIndex(sValue,g_sWearerID)) g_iOwnSelf = TRUE;
                    else g_iOwnSelf = FALSE;
                    sValue="";
                } else if (sToken == "tempowner")
                    setGlobalVariable("kTempOwner",sValue);
                else if (sToken == "group") {
                    setGlobalVariable("kGroup",sValue);
                    //check to see if the object's group is set properly
                    if (getGlobalVariable("kGroup") != "") {
                        if ((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == getGlobalVariable("kGroup")) setGlobalVariable("iGroupEnabled","1");
                        else setGlobalVariable("iGroupEnabled","0");
                    } else setGlobalVariable("iGroupEnabled","0");
                }
                else if (sToken == "public") setGlobalVariable("iOpenAccess",sValue);
                else if (sToken == "limitrange") setGlobalVariable("iLimitRange",sValue);
                else if (sToken == "norun") g_iRunawayDisable = (integer)sValue;
                else if (sToken == "trust") { 
                    //setAuthList(TRUST_LIST,llParseString2List(sValue, [","], [""]));
                    sValue="";
                    }
                else if (sToken == "block") {
                    //setAuthList(BLOCK_LIST,llParseString2List(sValue, [","], [""]));
                    sValue="";
                    }
                else if (sToken == "flavor") g_sFlavor = sValue;
            } else if (llToLower(sStr) == "settings=sent") {
                if (llJsonGetValue(getAuthList(OWNER_LIST),["owner"]) != "" && g_iFirstRun) {
                    SayOwners();
                    g_iFirstRun = FALSE;
                }
            }
        } else if (iNum == AUTH_REQUEST) {//The reply is: "AuthReply|UUID|iAuth" we rerute this to com to have the same prim ID 
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
            llSetTimerEvent(0.22);
            llMessageLinked(iSender,AUTH_REPLY, "AuthReply|"+(string)kID+"|"+(string)Auth(kID), llGetSubString(sStr,0,35));
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
                llSetTimerEvent(0.22);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                // integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                //Debug(sMessage);
                if (sMenu == "Auth") {
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu " + g_sParentMenu, kAv);
                    else {
                        list lTranslation=[
                            "+ Owner","add owner",
                            "+ Trust","add trust",
                            "+ Block","add block",
                            "− Owner","rm owner",
                            "− Trust","rm trust",
                            "− Block","rm block",
                            "Group ☐","group on",
                            "Group ☑","group off",
                            "Public ☐","public on",
                            "Public ☑","public off",
                            g_sFlavor+" ☐","ownself on",
                            g_sFlavor+" ☑","ownself off",
                            "Access List","list",
                            "Runaway","runaway"
                          ];
                        integer buttonIndex=llListFindList(lTranslation,[sMessage]);
                        if (~buttonIndex)
                            sMessage=llList2String(lTranslation,buttonIndex+1);
                        //Debug("Sending UserCommand "+sMessage);
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    }
                } else if (sMenu == "removeowner" || sMenu == "removetrust" || sMenu == "removeblock" ) {
                    string sCmd = "rm "+llGetSubString(sMenu,6,-1)+" ";
                    if (sMessage == UPMENU)
                        AuthMenu(kAv, iAuth);
                    else UserCommand(iAuth, sCmd +sMessage, kAv, TRUE);
                } else if (sMenu == "runawayMenu" ) {   //no chat commands for this menu, by design, so handle it all here
                    if (sMessage == "Yes") RunAway();
                    else if (sMessage == UPMENU) AuthMenu(kAv, iAuth);
                    else if (sMessage == "No") llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway aborted.",kAv);
                } if (llSubStringIndex(sMenu,"AddAvi") == 0) {
                    if ((key)sMessage)
                        AddUniquePerson(sMessage, llGetSubString(sMenu,6,-1), kAv); //should be safe to uase key2name here, as we added from sensor dialog
                    else if (sMessage == "BACK")
                        AuthMenu(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
            else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_AUTH","");
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }
    
    timer () {
        llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
        llSetTimerEvent(0.0);
    }
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}