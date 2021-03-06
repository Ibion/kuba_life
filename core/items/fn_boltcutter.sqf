#include "..\..\script_macros.hpp"
/*
	File: fn_boltcutter.sqf
	Author: Bryan "Tonic" Boardwine

	Description:
	Breaks the lock on a single door (Closet door to the player).
*/
private["_building","_door","_doors","_cpRate","_title","_progressBar","_titleText","_cp","_ui"];
_building = param [0,ObjNull,[ObjNull]];
private _home = false;
private _ownerName = "";

if(isNull _building) exitWith {};
if(!(_building isKindOf "House_F")) exitWith {hint localize "STR_ISTR_Bolt_NotNear";};
if(((nearestObject [[5553.5,7736.9,0],"Land_Dome_Small_F"]) == _building || (nearestObject [[5547.5,7735.9,0],"Land_Cargo_House_V1_F"]) == _building) && (west countSide playableUnits < (LIFE_SETTINGS(getNumber,"minimum_cops")))) exitWith {
	hint format [localize "STR_Civ_NotEnoughCops",(LIFE_SETTINGS(getNumber,"minimum_cops"))]
};



if((typeOf _building) == "Land_Cargo_House_V1_F" && (nearestObject [[5553.5,7736.9,0],"Land_Dome_Small_F"]) GVAR ["locked",true]) exitWith {hint localize "STR_ISTR_Bolt_Exploit"};
if(isNil "life_boltcutter_uses") then {life_boltcutter_uses = 0;};

_doors = FETCH_CONFIG2(getNumber,CONFIG_VEHICLES,(typeOf _building),"numberOfDoors");
_door = 0;
//Find the nearest door
for "_i" from 1 to _doors do {
	_selPos = _building selectionPosition format["Door_%1_trigger",_i];
	_worldSpace = _building modelToWorld _selPos;
		if(player distance _worldSpace < 5) exitWith {_door = _i;};
};
if(_door == 0) exitWith {hint localize "STR_Cop_NotaDoor"}; //Not near a door to be broken into.
if((_building GVAR [format["bis_disabled_Door_%1",_door],0]) == 0) exitWith {hint localize "STR_House_Raid_DoorUnlocked"};

if((nearestObject [[5553.5,7736.9,0],"Land_Dome_Small_F"]) == _building OR (nearestObject [[5547.5,7735.9,0],"Land_Cargo_House_V1_F"]) == _building) then {
	[[1,2],"STR_ISTR_Bolt_AlertFed",true,[]] remoteExecCall ["life_fnc_broadcast",RCLIENT];
} else {
	[0,"STR_ISTR_Bolt_AlertHouse",true,[profileName]] remoteExecCall ["life_fnc_broadcast",RCLIENT];
};

//Haus raid
private _ownerUid = (_building getVariable ["house_owner",["",""]]) select 0;
if (_ownerUid != "") then {_home = true};
if (_home && (!([_ownerUid] call life_fnc_isUIDActive))) exitWith {hint localize "STR_ISTR_Bolt_Offline"};
private _copsNeeded = LIFE_SETTINGS(getNumber,"copsHouseRaid");
if (({side _x isEqualTo west} count playableUnits < _copsNeeded) && _home) exitWith {hint format[localize "STR_Civ_NotEnoughCops",_copsNeeded]};
//Haus Raid

life_action_inUse = true;

if (_home) then {
    private _unitsToNotify = [];
    {
        if (_uid isEqualTo (getPlayerUID _x) || side _x isEqualTo west) then {_unitsToNotify pushBack _x};
        if (_uid isEqualTo (getPlayerUID _x)) then {_ownerName = name _x};
    } forEach playableUnits;
    if (count _unitsToNotify isEqualTo 0) exitWith {};
    [1,[_building,60,"Mil_dot","Ein Haus wird aufgebrochen!"]] remoteExec ["life_fnc_markers",_unitsToNotify];
    [1,format[localize "STR_ISTR_Bolt_Notify",_ownerName]] remoteExec ["life_fnc_broadcast",_unitsToNotify];
};

//Setup the progress bar
disableSerialization;
_title = localize "STR_ISTR_Bolt_Process";
5 cutRsc ["life_progress","PLAIN"];
_ui = GVAR_UINS "life_progress";
_progressBar = _ui displayCtrl 38201;
_titleText = _ui displayCtrl 38202;
_titleText ctrlSetText format["%2 (1%1)...","%",_title];
_progressBar progressSetPosition 0.01;
_cP = 0.050;
[] call SOCK_fnc_updateRequest;

switch (typeOf _building) do {
	case "Land_Dome_Small_F": {_cpRate = 0.002;};
	case "Land_Cargo_House_V1_F": {_cpRate = 0.002;};
	default {_cpRate = 0.04;}
};

for "_i" from 0 to 1 step 0 do {
	if(animationState player != "AinvPknlMstpSnonWnonDnon_medic_1") then {
		[player,"AinvPknlMstpSnonWnonDnon_medic_1",true] remoteExecCall ["life_fnc_animSync",RCLIENT];
		player switchMove "AinvPknlMstpSnonWnonDnon_medic_1";
		player playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
	};
	sleep 0.26;
	if(isNull _ui) then {
		5 cutRsc ["life_progress","PLAIN"];
		_ui = GVAR_UINS "life_progress";
		_progressBar = _ui displayCtrl 38201;
		_titleText = _ui displayCtrl 38202;
	};
	_cP = _cP + _cpRate;
	_progressBar progressSetPosition _cP;
	_titleText ctrlSetText format["%3 (%1%2)...",round(_cP * 100),"%",_title];
	if(_cP >= 1 OR !alive player) exitWith {};
	if(life_istazed) exitWith {}; //Tazed
	if(life_isknocked) exitWith {}; //Knocked
	if(life_interrupted) exitWith {};
};

//Kill the UI display and check for various states
5 cutText ["","PLAIN"];
player playActionNow "stop";
if(!alive player OR life_istazed OR life_isknocked) exitWith {life_action_inUse = false;};
if((player GVAR ["restrained",false])) exitWith {life_action_inUse = false;};
if(life_interrupted) exitWith {life_interrupted = false; titleText[localize "STR_NOTF_ActionCancel","PLAIN"]; life_action_inUse = false;};
life_boltcutter_uses = life_boltcutter_uses + 1;
life_action_inUse = false;

if(life_boltcutter_uses >= 1) then {
	[false,"boltcutter",1] call life_fnc_handleInv;
	life_boltcutter_uses = 0;
};

_dice = random(100);
	if(playerSide == west) then {
		_building SVAR [format["bis_disabled_Door_%1",_door],0,true]; //Unlock the door.
		_building setVariable["locked",false,true];
	}else{
		if(playerSide == civilian) then {
		exitWith {hint localize "Du kannst momentan in keine Häuser einbrechen!";};
	;}
	
/*
		if(_dice < 20) then {
			titleText[localize "STR_ISTR_Lock_Success","PLAIN"];
			_building SVAR [format["bis_disabled_Door_%1",_door],0,true]; //Unlock the door.
			_building setVariable["locked",false,true];
		} else {
			titleText[localize "STR_ISTR_Lock_Failed","PLAIN"];
		};
	};
*/
if(life_HC_isActive) then {
	[getPlayerUID player,profileName,"459"] remoteExecCall ["HC_fnc_wantedAdd",HC_Life];
} else {
	[getPlayerUID player,profileName,"459"] remoteExecCall ["life_fnc_wantedAdd",RSERV];
};
