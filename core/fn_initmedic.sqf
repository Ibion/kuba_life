#include "..\script_macros.hpp"
/*
	File: fn_initMedic.sqf
	Author: Bryan "Tonic" Boardwine

	Description:
	Initializes the medic..
*/
private["_end"];
player addRating 99999999;
waitUntil {!(isNull (findDisplay 46))};

if((FETCH_CONST(life_medicLevel)) < 1 && (FETCH_CONST(life_adminlevel) == 0)) exitWith {
	["Notwhitelisted",FALSE,TRUE] call BIS_fnc_endMission;
	sleep 35;
};

if(EQUAL(LIFE_SETTINGS(getNumber,"restrict_medic_weapons"),1)) then {
	[] spawn {
		for "_i" from 0 to 1 step 0 do {
			waitUntil {sleep 3; currentWeapon player != ""};
			removeAllWeapons player;
		};
	};
};


[] call life_fnc_spawnMenu;
waitUntil{!isNull (findDisplay 38500)}; //Wait for the spawn selection to be open.
waitUntil{isNull (findDisplay 38500)}; //Wait for the spawn selection to be done.

switch (FETCH_CONST(life_mediclevel)) do
{
	case 1: { life_paycheck = life_paycheck + 50; }; //Level 1 Rekrut
    case 2: { life_paycheck = life_paycheck + 100; }; //Level 2 Officer
    case 3: { life_paycheck = life_paycheck + 200; }; //Level 3 Patrol
    case 4: { life_paycheck = life_paycheck + 300; }; //Level 4 Detec
    case 5: { life_paycheck = life_paycheck + 400; }; //Level 5 Searg
    case 6: { life_paycheck = life_paycheck + 500; }; //Level 6 Lieu
    case 7: { life_paycheck = life_paycheck + 600; }; //Level 7 Capt
    case 8: { life_paycheck = life_paycheck + 700; }; //Level 8 Major
    case 9: { life_paycheck = life_paycheck + 800; }; //Level 9 Ass
	case 10: { life_paycheck = life_paycheck + 1000; }; //Level 10 Chief
	default { life_paycheck = life_paycheck };
};
