unit FirstBlood;

interface

implementation
const
	AddPoints = 5;					//Extra points as fistkill
	ColorConsoleText = $DD98FF10;	//Console text color
	ColorBigText = $FF3300;			//Big text color
	BigTextPosX = 284;				//Positon X
	BigTextPosY = 367;				//Positon Y
	BigTextScale = 0.155;			//Text size
	BitTextDisplayTime = 330; 		//Time in ms
	BigTextLayer = 77;				//If bigtext conflict with other texts on the screen change it

//-------------------------------------------------------------------

var
	FirstBlood: boolean;

procedure ChangeAfter(Next: string);
begin
	FirstBlood := true;
end;

procedure OnKill(Killer, Victim: TActivePlayer; BulletId: Byte);
begin
  if Killer.Team <> Victim.Team then begin
	if FirstBlood then begin
		if (Killer.ID <> Victim.ID) then begin
			FirstBlood := false;
			Killer.Kills := Killer.Kills+AddPoints;
			Players.WriteConsole('FIRSTBLOOD! '+Victim.Name+' killed by '+Killer.Name,ColorConsoleText);
			Players.WriteConsole(Killer.Name+' gained +'+inttostr(AddPoints)+' extra point !!',ColorConsoleText);
			Players.BigText(BigTextLayer,'FIRST BLOOD !',BitTextDisplayTime,ColorBigText,BigTextScale,BigTextPosX,BigTextPosY);
		end;
	end;
  end;
end;

procedure ScriptDecl();
var i:byte;
begin
	for i := 1 to 32 do Players[i].OnKill := @OnKill;
	Map.OnAfterMapChange := @ChangeAfter;
	firstblood := true;
end;
	
initialization
begin
	ScriptDecl();
end;

finalization;
end.