const
  HpHealed= 10;       //hp regenerated per heal
  HealForPoint= 65; //how much hp medic must heal to get 1 point (hp in realistic is 65)
  HealDistance= 60;  //distance of heal (in strange units, 14=1m or sth)
  Color= $44AA44;    //color of msgs

var
  Medic: array[1..2] of byte;
  Healed: array[1..2] of integer;
  MaxHP: byte;
  Vest: integer;

procedure Reset;
begin
  if Command('/realistic') = 1 then MaxHP:= 65 else MaxHP:= 150;
  Medic[1]:= 0;
  Medic[2]:= 0;
  Healed[1]:= 0;
  Healed[2]:= 0;
end;

procedure ActivateServer();
begin
  Reset;
end;

procedure OnMapChange(NewMap: string);
begin
  Reset;
  WriteConsole(0,'Medic position is now free. Write !medic to apply.',Color);
end;

procedure MedicQuit(Team: byte);
begin
  WriteConsole(0,IDToName(Medic[Team])+' is no longer the '+iif(Team=1,'alpha','bravo')+' team''s medic!',iif(Team=1,$AAAA00,$00AAAA));
  Medic[Team]:= 0;
  Healed[Team]:= 0;
end;

procedure Heal(Team: byte);
var
  HP, FinalHeal: integer;
  i: byte;
begin
  for i:= 1 to 32 do if GetPlayerStat(i,'Active') = true then if GetPlayerStat(i,'Alive') = true then if GetPlayerStat(i,'Health') < MaxHP then
   if Team = GetPlayerStat(i,'Team') then if
    Distance(GetPlayerStat(Medic[Team],'X'),GetPlayerStat(Medic[Team],'Y'),GetPlayerStat(i,'X'),GetPlayerStat(i,'Y')) <= HealDistance then begin

    // Test pour fi x le heal de la veste
    //Vest := GetPlayerStat(i,'Vest');
    //WriteConsole(Medic[Team],IntToStr(Vest),Color);
	
    DrawText(Medic[Team],'Healing',60,Color,0.1,160,350);
    if GetPlayerStat(i,'Health') <= (MaxHP-HpHealed) then HP:= HpHealed else HP:= MaxHP-GetPlayerStat(i,'Health');
    
	// if medic heal less
    if i = Medic[Team] then
      FinalHeal := HP div 2
    else
      FinalHeal := HP;
	
	DoDamage(i,-FinalHeal);
    if Medic[Team] <> i then begin
      inc(Healed[Team],HP);
      if Healed[Team] > HealForPoint then begin
        WriteConsole(Medic[Team],'You got 1 point for healing.',Color);
        SetScore(Medic[Team],GetPlayerStat(Medic[Team],'Kills')+1);
        Healed[Team]:= 0;
      end;
    end;
  end;
end;

procedure OnPlayerSpeak(ID: byte; Text: string);
var T: byte;
begin
  if RegExpMatch('^!(medic|med|medi)$',LowerCase(Text)) then if (GetPlayerStat(ID,'Team')=1) or (GetPlayerStat(ID,'Team')=2) then begin
    T:= GetPlayerStat(ID,'Team');
    if Medic[T]=0 then begin
      WriteConsole(0,IDToName(ID)+' is now the '+iif(T=1,'alpha','bravo')+' team''s medic!',iif(T=1,$AAAA00,$00AAAA));
      Medic[T]:= ID;
    end else if Medic[T] = ID then begin
      MedicQuit(T);
    end else WriteConsole(ID,IDToName(Medic[T])+' is already your team''s medic!',Color);
  end;
end;

procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
  if (Team = 1) or (Team = 2) then if ID = Medic[Team] then MedicQuit(Team);
end;

procedure OnJoinTeam(ID, Team: byte);
begin
  if (Medic[1]=ID) or (Medic[2]=ID) then MedicQuit(iif(Medic[1]=ID,1,2));
  if (Team = 1) or (Team = 2) then if Medic[Team]=0 then WriteConsole(ID,'Medic position is free. Write !medic to apply.',Color) else
   WriteConsole(ID,IDToName(Medic[Team]) + ' is your team''s medic.',Color);
end;

procedure OnWeaponChange(ID, PrimaryNum, SecondaryNum: byte);
begin
  if (Medic[1]=ID) or (Medic[2]=ID) then if GetPlayerStat(ID,'Health') > 0 then Heal(iif(Medic[1]=ID,1,2));
end;

