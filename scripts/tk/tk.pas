const
	NUMBER_OF_PLAYERS=18;
	BANPOINT_MAX=10;
	BANPOINT_BANTIME=30;

var
	killLog,banpointCount,voteTime,spawnKill: array[1..NUMBER_OF_PLAYERS] of byte;
	DMGF: array [1..NUMBER_OF_PLAYERS] of integer;
	score,survival_timer: integer;
	survival: boolean;

procedure BanPoint(ID: byte);
begin
	DMGF[ID]:=0;
	banpointCount[ID]:=banpointCount[ID]+1;
	if banpointCount[ID]=BANPOINT_MAX then begin
		WriteConsole(ID,'You teamkilled too much, bye bye!',$EE00FFFF);;
		WriteConsole(ID,'Banned for '+inttostr(BANPOINT_BANTIME)+' minutes.',$EE00FFFF);;
		DrawText(ID,'TK Ban',330,RGB(255,0,0),0.5,48,260);
		BanPlayer(ID,BANPOINT_BANTIME);
	end	else begin
		WriteConsole(ID,'You now have '+inttostr(banpointCount[ID])+'/'+inttostr(BANPOINT_MAX)+' banpoints',$EE00FFFF);
		DrawText(ID,inttostr(banpointCount[ID])+'/'+inttostr(BANPOINT_MAX)+' banpoints',330,RGB(255,0,0),0.3,2,260);
	end;
end;

procedure showVoteMenu(k,v: byte);
begin
	killLog[v]:=k;
	voteTime[v]:=30;
	WriteConsole(k,'You have teamkilled '+GetPlayerStat(v,'name'),$EE00FFFF);
	WriteConsole(v,'You have been teamkilled by '+GetPlayerStat(k,'name')+'. You have 30 seconds to decide:',$EE00FFFF);
	WriteConsole(v,'!1 - Forgive player (no banpoint)',$EE00CCCC);
	WriteConsole(v,'!2 - Kill player now + Banpoint',$EE00CCCC);
	WriteConsole(v,'!3 - Banpoint only',$EE00CCCC);
	if survival then WriteConsole(v,'!4 - Kill player next round + Banpoint',$EE00CCCC);
end;

procedure ActivateServer();
begin
	if ReadINI('soldat.ini','GAME','Survival_Mode','0') = '1' then survival:=true else survival:=false;
end;

procedure AppOnIdle(Ticks: integer);
var
	i: byte;
begin
	for i:=1 to NUMBER_OF_PLAYERS do
		if voteTime[i]>0 then begin
			voteTime[i]:=voteTime[i]-1;
			if voteTime[i]=0 then WriteConsole(i,'Your votetime is over, sorry.',$EE00FFFF);
		end;
	if survival then begin
		if score<AlphaScore+BravoScore then survival_timer:=12;
		score:=AlphaScore+BravoScore;
		if survival_timer>0 then begin
			survival_timer:=survival_timer-1;
			if survival_timer=0 then for i:=1 to NUMBER_OF_PLAYERS do if spawnKill[i]=1 then begin
				DoDamage(i,4000);
				WriteConsole(i,'You were marked as "Kill next round".',$EE00FFFF);
				spawnKill[i]:=0;
			end;
		end;
	end;
end;

function OnRequestGame(IP: string; State: integer): integer;
begin
	Result:=State;
end;

procedure OnJoinTeam(ID, Team: byte);
begin
end;

procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
	killLog[ID]:=0;
	spawnKill[ID]:=0;
	banpointCount[ID]:=0;
	voteTime[ID]:=0;
	DMGF[ID]:=0;
end;

procedure OnPlayerKill(Killer, Victim: byte; Weapon: string);
begin
	if (BANPOINT_MAX>0)and(Killer <> Victim)and(GetPlayerStat(Killer,'team')=GetPlayerStat(Victim,'team')) then showVoteMenu(Killer,Victim);
	DMGF[Killer] := 0;
end;

function OnPlayerCommand(ID: Byte; Text: string): boolean;
var
	votable: boolean;
begin
	Result := false;
	if BANPOINT_MAX>0 then if LowerCase(GetPiece(Text,' ',0))='/tk' then if (killLog[ID]>0)and(voteTime[ID]<>0) then begin
		votable:=false;
		case LowerCase(GetPiece(Text,' ',1)) of
			'1': begin
				WriteConsole(killLog[ID],GetPlayerStat(ID,'name')+' has forgiven you.',$EE00FFFF);
				votable:=true;
			end;
			'2': begin
				WriteConsole(killLog[ID],GetPlayerStat(ID,'name')+' has chosen to kill you.',$EE00FFFF);	
				Command('/kill ' + inttostr(killLog[ID]));
				BanPoint(killLog[ID]);
				votable:=true;
			end;	
			'3': begin
				BanPoint(killLog[ID]);
				votable:=true;
				case (strtoint(FormatDate('zzz')) div 50) of
					0: WriteConsole(killLog[id],'TKers have a small penis!',$EE00FFFF);
					1: WriteConsole(killLog[id],'Trashcat is not amused!',$EE00FFFF);
					2: WriteConsole(killLog[id], IDtoName(id) + 'hates you! >:(',$EE00FFFF);
					3: WriteConsole(killLog[id],'SpliNter himself is coming to rape you tonight.',$EE00FFFF);
					4: WriteConsole(killLog[id],'Everytime you teamkill, god kills a kitten',$EE00FFFF);
					5: WriteConsole(killLog[id],'Teamkilling makes Boogieman haunt you.',$EE00FFFF);		    
					6: WriteConsole(killLog[id],'Watch your damn fire!',$EE00FFFF);	
					7: Command('/say ' + IDtoName(killLog[id]) + ' has a small penis!');
					8: WriteConsole(killLog[id],'You now have 1337/' + inttostr(BANPOINT_MAX) + ' banpoints',$EE00FFFF);
					9: WriteConsole(killLog[id],'If it TKs, we can kick it!',$EE00FFFF);
					10: WriteConsole(killLog[id],'Son of a bitch!',$EE00FFFF);
					11: WriteConsole(killLog[id],IDtoName(id) + ' wants your number. <3',$EE00FFFF);
					12: begin WriteConsole(killLog[id],'SURPRISE!!',$EE00FFFF); Command('/setteam5 ' + inttostr(killLog[id])); end;
					13: WriteConsole(killLog[id],'You evil teamkilling bitch!',$EE00FFFF);
					14: WriteConsole(killLog[id],'tOMFG NOOB!!1!1',$EE00FFFF);
					15: WriteConsole(killLog[id],'<(Oo)<   <(OO)>   >(oO)>',$EE00FFFF);
					16: WriteConsole(killLog[id],'Poopface.',$EE00FFFF);
					17: WriteConsole(killLog[id],'TKing leads to bans, did you know?',$EE00FFFF);
					18: WriteConsole(killLog[id],'Son of a bitch!',$EE00FFFF);
					19: begin WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); end;
			  end;
			end;
			'4': begin
				if survival then begin
					WriteConsole(killLog[ID],GetPlayerStat(ID,'name')+' has chosen to kill you on next spawn.',$EE00FFFF);	
					spawnKill[killLog[id]]:=1;
					BanPoint(killLog[id]);
					votable:=true;
				end;
			end;
		end;
		if votable then begin
			WriteConsole(ID,'Vote successful.',$EE00FFFF);
			killLog[id]:=0;
			voteTime[id]:=0;
		end;
	end;
end;

procedure OnPlayerSpeak(ID: byte; Text: string);
var
	votable: boolean;
begin
	if copy(text,1,10) = '!banpoints' then WriteConsole(ID,'You currently have ' + inttostr(banpointCount[ID]) + '/' + inttostr(BANPOINT_MAX) + ' banpoints',$EE00FFFF);
	if BANPOINT_MAX>0 then if (killLog[ID]>0)and(voteTime[ID]<>0) then begin
		votable:=false;
		if text = '!1' then begin
			WriteConsole(killLog[ID],GetPlayerStat(ID,'name')+' has forgiven you.',$EE00FFFF);
			votable:=true;
		end;
		if text = '!2' then begin
			WriteConsole(killLog[ID],GetPlayerStat(ID,'name')+' has chosen to kill you.',$EE00FFFF);	
			Command('/kill ' + inttostr(killLog[ID]));
			BanPoint(killLog[ID]);
			votable:=true;
		end;
		if text = '!3' then begin
			BanPoint(killLog[ID]);
			votable:=true;
			case (strtoint(FormatDate('zzz')) div 50) of
				0: WriteConsole(killLog[id],'TKers have a small penis!',$EE00FFFF);
				1: WriteConsole(killLog[id],'Trashcat is not amused!',$EE00FFFF);
				2: WriteConsole(killLog[id], IDtoName(id) + 'hates you! >:(',$EE00FFFF);
				3: WriteConsole(killLog[id],'SpliNter himself is coming to rape you tonight.',$EE00FFFF);
				4: WriteConsole(killLog[id],'Everytime you teamkill, god kills a kitten',$EE00FFFF);
				5: WriteConsole(killLog[id],'Teamkilling makes Boogieman haunt you.',$EE00FFFF);		    
				6: WriteConsole(killLog[id],'Watch your damn fire!',$EE00FFFF);	
				7: Command('/say ' + IDtoName(killLog[id]) + ' has a small penis!');
				8: WriteConsole(killLog[id],'You now have 1337/' + inttostr(BANPOINT_MAX) + ' banpoints',$EE00FFFF);
				9: WriteConsole(killLog[id],'If it TKs, we can kick it!',$EE00FFFF);
				10: WriteConsole(killLog[id],'Son of a bitch!',$EE00FFFF);
				11: WriteConsole(killLog[id],IDtoName(id) + ' wants your number. <3',$EE00FFFF);
				12: begin WriteConsole(killLog[id],'SURPRISE!!',$EE00FFFF); Command('/setteam5 ' + inttostr(killLog[id])); end;
				13: WriteConsole(killLog[id],'You evil teamkilling bitch!',$EE00FFFF);
				14: WriteConsole(killLog[id],'tOMFG NOOB!!1!1',$EE00FFFF);
				15: WriteConsole(killLog[id],'<(Oo)<   <(OO)>   >(oO)>',$EE00FFFF);
				16: WriteConsole(killLog[id],'Poopface.',$EE00FFFF);
				17: WriteConsole(killLog[id],'TKing leads to bans, did you know?',$EE00FFFF);
				18: WriteConsole(killLog[id],'Son of a bitch!',$EE00FFFF);
				19: begin WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); WriteConsole(killLog[id],'SPAM',$EE00FFFF); end;
		  end;
		end;	
		if text = '!4' then begin
			if survival then begin
				WriteConsole(killLog[ID],GetPlayerStat(ID,'name')+' has chosen to kill you on next spawn.',$EE00FFFF);	
				spawnKill[killLog[id]]:=1;
				BanPoint(killLog[id]);
				votable:=true;
			end;
		end;
		if votable then begin
			WriteConsole(ID,'Vote successful.',$EE00FFFF);
			killLog[id]:=0;
			voteTime[id]:=0;
		end;
	end;
end;

function OnPlayerDamage(Victim,Shooter: Byte;Damage: Integer): integer;
var
	tmpDmg: double;
	MaxHealth: integer;
begin
	tmpDmg := Damage;
	MaxHealth:= iif(Command('/realistic')='1',65,150);
	if(tmpDmg>MaxHealth) then tmpDmg:=MaxHealth;
	if (Victim <> Shooter) then begin
		if (StrtoInt(ReadINI('soldat.ini','GAME','Friendly_Fire','0')) = 1) and (GetPlayerStat(Shooter,'team')=GetPlayerStat(Victim,'team')) then begin
			DMGF[Shooter] := DMGF[Shooter] + Round(tmpDmg);
			if ReadINI('soldat.ini','GAME','Realistic_Mode','0') = '1' then begin
				if DMGF[Shooter] <= 21 then WriteConsole(Shooter,'Do not hurt your people!',$EE00FFFF);
				if (DMGF[Shooter] >= 22) and (DMGF[Shooter] <= 43) then WriteConsole(Shooter,'Please stop hurting her because we apply a penalty.',$EE00FFFF);
				if (DMGF[Shooter] >= 44) and (DMGF[Shooter] <= 65) then begin
					WriteConsole(Shooter,'We are sorry but we have to punish you!',$EE00FFFF);
					killLog[Victim]:=Shooter;
					BanPoint(killLog[Victim]);
				end;
				if ReadINI('soldat.ini','GAME','Realistic_Mode','0') = '0' then begin
					if DMGF[Shooter] <= 50 then WriteConsole(Shooter,'Do not hurt your people!',$EE00FFFF);
					if (DMGF[Shooter] >= 51) and (DMGF[Shooter] <= 100) then WriteConsole(Shooter,'Please stop hurting her because we apply a penalty.',$EE00FFFF);
					if (DMGF[Shooter] >= 101) and (DMGF[Shooter] <= 150) then begin
						WriteConsole(Shooter,'We are sorry but we have to punish you!',$EE00FFFF);
						killLog[Victim]:=Shooter;
						BanPoint(killLog[Victim]);
					end;
				end;
			end;
		end;
	end;
	Result:=Damage;
end;

procedure OnMapChange(NewMap: String);
var
	i: byte;
begin
	for i:=1 to NUMBER_OF_PLAYERS do begin
		banpointCount[i]:=0;
		voteTime[i] := 0;
		spawnKill[i] := 0;
		DMGF[i] := 0;
	end;
	WriteConsole(0,'All banpoints reset.',$EE00CCCC);
end;