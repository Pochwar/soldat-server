unit Medic;

interface

implementation

const
  HpHealed= 10;       //hp regenerated per heal
  HealForPoint= 65; //how much hp medic must heal to get 1 point (hp in realistic is 65)
  HealDistance= 60;  //distance of heal (in strange units, 14=1m or sth)
  Color= $44AA44;    //color of msgs

var
  Medic: array[1..2] of byte;
  Healed: array[1..2] of integer;
  MaxHP: byte;

procedure Reset;
begin
  if Game.Realistic then MaxHP:= 65 else MaxHP:= 150;
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
  Players.WriteConsole('Medic position is now free. Write !medic to apply.',Color);
end;

procedure MedicQuit(Team: byte);
begin
  Players.WriteConsole(Players[Medic[Team]].Name +' is no longer the '+iif(Team=1,'alpha','bravo')+' team''s medic!',iif(Team=1,$AAAA00,$00AAAA));
  Medic[Team]:= 0;
  Healed[Team]:= 0;
end;

procedure HealPlayer(MedicID, TargetID: byte);
var
  HP, FinalHeal: integer;
begin
  if not Players[TargetID].Active or not Players[TargetID].Alive then exit;
  if round(Players[TargetID].Health) >= MaxHP then exit;

  if Distance(Players[MedicID].X, Players[MedicID].Y, Players[TargetID].X, Players[TargetID].Y) > HealDistance then exit;
  Players[MedicID].BigText(77,'Healing',60,Color,0.1,160,350);
  if round(Players[TargetID].Health) <= (MaxHP - HpHealed) then
    HP := HpHealed
  else
    HP := round(MaxHP - Players[TargetID].Health);

  if MedicID = TargetID then
    FinalHeal := HP div 2
  else
    FinalHeal := HP;

  Players[TargetID].Health := Players[TargetID].Health + Single(FinalHeal);

  if MedicID <> TargetID then begin
    Inc(Healed[Players[MedicID].Team], HP);
    if Healed[Players[MedicID].Team] > HealForPoint then begin
      Players[MedicID].WriteConsole('You got 1 point for healing.', Color);
      Players[MedicID].Kills := Players[MedicID].Kills + 1;
      Healed[Players[MedicID].Team] := 0;
    end;
  end;
end;

procedure HealNearby;
var
  t, i: byte;
begin
  for t := 1 to 2 do if Medic[t] > 0 then
    for i := 1 to 32 do if Players[i].Active and Players[i].Alive and (Players[i].Team = t) then
      if i <> Medic[t] then HealPlayer(Medic[t], i);
end;

procedure OnPlayerSpeak(Player: TActivePlayer; Text: string);
var T: byte;
begin
  Text := LowerCase(Text);
  if (Text = '!medic') or (Text = '!med') or (Text = '!medi') then if (Player.Team=1) or (Player.Team=2) then begin
    T:= Player.Team;
    if Medic[T]=0 then begin
      Players.WriteConsole(Player.Name+' is now the '+iif(T=1,'alpha','bravo')+' team''s medic!',iif(T=1,$AAAA00,$00AAAA));
      Medic[T]:= Player.ID;
    end else if Medic[T] = Player.ID then begin
      MedicQuit(T);
    end else Player.WriteConsole(Players[Medic[T]].Name+' is already your team''s medic!',Color);
  end;
end;

procedure OnLeaveGame(Player: TActivePlayer; Kicked: Boolean);
begin
  if (Player.Team = 1) or (Player.Team = 2) then if Player.ID = Medic[Player.Team] then MedicQuit(Player.Team);
end;

procedure OnJoinTeam(Player: TActivePlayer; Team: TTeam);
begin
  if (Medic[1]=Player.ID) or (Medic[2]=Player.ID) then MedicQuit(iif(Medic[1]=Player.ID,1,2));
  if (Team.ID = 1) or (Team.ID = 2) then if Medic[Team.ID]=0 then Players[Player.ID].WriteConsole('Medic position is free. Write !medic to apply.',Color) else
   Players[Player.ID].WriteConsole(Players[Medic[Team.ID]].Name + ' is your team''s medic.',Color);
end;

procedure OnWeaponChange(Player: TActivePlayer; Primary, Secondary: TPlayerWeapon);
begin
  if (Medic[1] = Player.ID) or (Medic[2] = Player.ID) then
    HealPlayer(Player.ID, Player.ID); // Medic heals himself only
end;

procedure OnClock(Ticks: integer);
begin
  if Ticks mod 30 = 0 then // every ~0.5 seconds
    HealNearby;
end;

procedure ScriptDecl();
var i:byte;
begin
	for i := 1 to 32 do Players[i].onSpeak := @OnPlayerSpeak;
	for i := 1 to 32 do Players[i].OnWeaponChange := @OnWeaponChange;
	for i := 1 to 2 do Game.Teams[i].onJoin := @OnJoinTeam;
	Map.OnAfterMapChange := @OnMapChange;
	Game.OnLeave := @OnLeaveGame;
	Game.OnClockTick := @OnClock;
end;

initialization
begin
	ScriptDecl();
	ActivateServer();
end;

finalization;
end.