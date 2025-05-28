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

procedure Heal(Team: byte);
var
  HP, FinalHeal: integer;
  i: byte;
begin
  for i:= 1 to 32 do

  if Players[i].Active = true then if Players[i].Alive = true then if round(Players[i].Health) < MaxHP then if Team = Players[i].Team then
    if Distance(Players[Medic[Team]].X,Players[Medic[Team]].Y,Players[i].X,Players[i].Y) <= HealDistance then begin

    Players[Medic[Team]].BigText(77,'Healing',60,Color,0.1,160,350);
	if round(Players[i].Health) <= (MaxHP-HpHealed) then HP:= HpHealed else HP:= round(MaxHP-Players[i].Health);
    
	// if medic, heal less
    if i = Medic[Team] then
      FinalHeal := HP div 2
    else
      FinalHeal := HP;
	
	Players[i].Health := Players[i].Health + Single(FinalHeal);

    if Medic[Team] <> i then begin
      inc(Healed[Team],HP);
      if Healed[Team] > HealForPoint then begin
        Players[Medic[Team]].WriteConsole('You got 1 point for healing.',Color);
		Players[Medic[Team]].Kills := Players[Medic[Team]].Kills+1;
        Healed[Team]:= 0;
      end;
    end;
  end; 
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
  if (Medic[1]=Player.ID) or (Medic[2]=Player.ID) then if Players[Player.ID].Health > 0 then Heal(iif(Medic[1]=Player.ID,1,2));
end;

procedure ScriptDecl();
var i:byte;
begin
	for i := 1 to 32 do Players[i].onSpeak := @OnPlayerSpeak;
	for i := 1 to 32 do Players[i].OnWeaponChange := @OnWeaponChange;
	for i := 1 to 2 do Game.Teams[i].onJoin := @OnJoinTeam;
	Map.OnAfterMapChange := @OnMapChange;
	Game.OnLeave := @OnLeaveGame;
end;

initialization
begin
	ScriptDecl();
	ActivateServer();
end;

finalization;
end.