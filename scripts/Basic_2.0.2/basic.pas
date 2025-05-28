unit Basic;

interface

implementation

const
	ScriptVer = '2.0.2';

type Pinger = record
	Sum:	integer;
	Count:	integer;
	Max:	integer;
end;

type MapVotingSystem = record
	VoteTimeLeft, TimeToStartVoting, VoteType, VotedPlayersCount: integer;
	Lastmap: String;
	Voted: array[1..32] of boolean;
end;

var
	SettingData: TIniFile;
	CommandsList, AdminCommandsList, RulesList, SpreeList, AdminsHWIDList, MapsForDisplayList, AdminsList: TStringList;
	MapSystem: MapVotingSystem;
	PlayerPingTrack: array[1..32] of Pinger;
	Spree, Spec_Time: array[1..32] of integer;
	WhoisAdminTimer: integer;

function GetPieceSC3(Str, Reg: string; Number: Word): string;
var Res: TStringList;
begin
	Result:='';
	try
		Res := File.CreateStringList;
		SplitRegExpr(QuoteRegExprMetaChars(Reg), Str, Res);
		Result := Res.Strings[Number];
	except
		Result := '';
	finally
		Res.Free;
	end;
end;

function ContainsStrSC3(const AText, ASubText: string): Boolean;
begin
	Result := Pos(ASubText,AText)>0;
end;

function FullReason(Str, Reg: string; Number: Word): string;
var Res: TStringList; i: integer;
begin
	Result := '';
	try
		Res := File.CreateStringList;
		SplitRegExpr(QuoteRegExprMetaChars(Reg), Str, Res);
		for i := 0 to Res.Count-1 do if i >= Number then if Result = '' then Result := Res[i] else Result := Result+' '+Res[i];
	except
		Result := '';
	finally
		Res.Free;
	end;
end;

function FindPlayer(s: string): integer;
var i: byte;
begin
	Result := -1;
	try
		i := StrToInt(s);
		if (i > 0) and (i < 33) and (Players[i].Active) then begin
			Result := i; 
			exit; 
		end;
	except
	end;
	for i := 1 to 32 do if Players[i].Active then begin
		if ContainsStrSC3(LowerCase(Players[i].Name), s) then begin
			Result := i; 
			exit;
		end;
	end;
end;

function ZeroFill(S: string; Peak: integer; IsEnabled: boolean): string;
var i, m: integer;
begin
	if IsEnabled then begin
		m := Peak - length(S);
		for i:= 1 to m do S := '0' + S;
    end;
	result := S;
end;

procedure DisplayArrayTables(SoucreInputTable: TStringList; Rows: integer; SmallCharacters, Sorting, PublicDisplay: boolean; Color: longint; Player: TActivePlayer);
var OperatingTable: array of array of string; ListToPrint, TempStringList: TStringList; TempString: string; MinColumns, SoucreUsingTableCount, i, b, StartAdd, TempLen, MaxStringLenght: integer; 
begin
	if SoucreInputTable.Count = 0 then begin
		Player.WriteConsole('There is no list to display!',Color);
		exit;
	end;
	if SoucreInputTable.Count = 1 then begin
		TempString := SoucreInputTable[0];
		if SmallCharacters then while Length(TempString) < 135 do TempString := TempString+'                                                                                ';
		if PublicDisplay then Players.WriteConsole(TempString,Color) else Player.WriteConsole(TempString,Color);
		exit;
	end;
	if Sorting then begin
		for i := 0 to SoucreInputTable.Count-1 do begin
			TempLen := length(SoucreInputTable[i]); 
			if TempLen > MaxStringLenght then MaxStringLenght := TempLen;
		end;
		TempLen := 0;
		TempStringList := File.CreateStringList();
		for i := 0 to SoucreInputTable.Count-1 do TempStringList.Append(ZeroFill(inttostr(Length(SoucreInputTable[i])),MaxStringLenght,true)+#9+SoucreInputTable[i]);
		TempStringList.Sort;
		for i := 0 to TempStringList.Count-1 do begin
			TempStringList[i] := GetPieceSC3(TempStringList[i],#9,1);
			TempStringList.Move(i, 0);
		end;
		SoucreInputTable.Clear;
		SoucreInputTable.AddStrings(TempStringList);
		TempStringList.Free;
	end;
	if Rows < 2 then begin
		for i := 0 to SoucreInputTable.Count-1 do begin
			if SmallCharacters then while Length(SoucreInputTable[i]) < 135 do SoucreInputTable[i] := SoucreInputTable[i]+'                                                                                ';
			if PublicDisplay then Players.WriteConsole(SoucreInputTable[i],Color) else Player.WriteConsole(SoucreInputTable[i],Color);
		end;
		exit;
	end;
	if Rows >= SoucreInputTable.Count then Rows := SoucreInputTable.Count;
	MinColumns := SoucreInputTable.Count;
	setLength(OperatingTable,MinColumns);	for i := 0 to MinColumns-1 do setLength(OperatingTable[i],Rows);
	SoucreUsingTableCount := 0;
	for i := 0 to MinColumns do begin
		for b := 0 to Rows-1 do begin
			if SoucreUsingTableCount = SoucreInputTable.Count then begin
				setLength(OperatingTable,i+1);
				MinColumns := i;
				continue;
			end;
			OperatingTable[i][b] := SoucreInputTable[SoucreUsingTableCount];
			SoucreUsingTableCount := SoucreUsingTableCount + 1;
		end;
	end;
	if OperatingTable[GetArrayLength(OperatingTable)-1][0] = '' then begin
		MinColumns := MinColumns-1;
		setLength(OperatingTable,GetArrayLength(OperatingTable)-1);
	end;
	ListToPrint := File.CreateStringList();
	for i := 0 to MinColumns do ListToPrint.Append(OperatingTable[i][0]+'   ');
	StartAdd := 1;
	while StartAdd <> Rows do begin
		for i := 0 to MinColumns do if Length(ListToPrint[i]) > TempLen then TempLen := Length(ListToPrint[i]);
		for i := 0 to MinColumns do begin
			while Length(ListToPrint[i]) < TempLen do ListToPrint[i] := ListToPrint[i] + ' ';
			ListToPrint[i] := ListToPrint[i] + OperatingTable[i][StartAdd]+'   ';
		end;
		StartAdd := StartAdd + 1;
	end;
	for i := 0 to ListToPrint.Count-1 do begin
		if SmallCharacters then while Length(ListToPrint[i]) < 135 do ListToPrint[i] := ListToPrint[i]+'                                                                                ';
		if PublicDisplay then Players.WriteConsole(ListToPrint[i],Color) else Player.WriteConsole(ListToPrint[i],Color);
	end;
	ListToPrint.Free;
end;

procedure MixMapList();
var i: integer; 
begin
	MapsForDisplayList.Free;
	MapsForDisplayList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
	for i := MapsForDisplayList.Count-1 downto 0 do MapsForDisplayList.Exchange(i, Random(0,i+1));
	MapsForDisplayList.SaveToFile(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
	Game.LoadList(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
end;

procedure ShowRules(Player: TActivePlayer);
var i: integer; 
begin
	if SettingData.ReadBool('Rules','Color_Identify',true) then begin
		for i := 0 to RulesList.Count-1 do begin
			try
				Player.WriteConsole(GetPieceSC3(RulesList[i],#9,1),strtoint(GetPieceSC3(RulesList[i],#9,0)));
			except
				Players.WriteConsole('Show rules, problem!', SettingData.ReadInteger('Rules','Color_Basic_Bad',$ff0033));
				exit;
			end;
		end;
	end else for i := 0 to RulesList.Count-1 do Player.WriteConsole(RulesList[i], SettingData.ReadInteger('Rules','Color_Basic_Good',$00BFFF));
end;

procedure Timers(Ticks: integer);
var i: byte; SumPings, AveragePing: integer;
begin
	if SettingData.ReadBool('Whoisadmin','Active',true) then begin
		if WhoisAdminTimer > 0 then begin
			Dec(WhoisAdminTimer, 1);
			if WhoisAdminTimer = 0 then begin
				if SettingData.ReadBool('Whoisadmin','Count_TCP',true) then if AdminsList.Count = 0 then Players.WriteConsole('There''s no TCP admin connected.', SettingData.ReadInteger('Whoisadmin','Color_Bad',$ff0033)) else begin
					if AdminsList.Count = 1 then Players.WriteConsole('There''s 1 TCP admin connected:', SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF)) else Players.WriteConsole('There''re '+IntToStr(AdminsList.Count)+' TCP admins connected:', SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF));
					for i := 0 to AdminsList.Count-1 do Players.WriteConsole(AdminsList[i], SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF));
					AdminsList.Clear;
				end;
				if SettingData.ReadBool('Whoisadmin','Count_IN_GAME',true) then begin
					for i := 1 to 32 do if players[i].IsAdmin then AdminsList.Append(players[i].Name);		
					if AdminsList.Count = 0 then Players.WriteConsole('There''s no In-Game admin connected.', SettingData.ReadInteger('Whoisadmin','Color_Bad',$ff0033)) else begin
						if AdminsList.Count = 1 then Players.WriteConsole('There''s 1 In-Game admin connected:', SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF)) else Players.WriteConsole('There''re '+IntToStr(AdminsList.Count)+' In-Game admins connected:', SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF));
						for i := 0 to AdminsList.Count-1 do Players.WriteConsole(AdminsList[i], SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF));
						AdminsList.Clear;
					end;
				end;
			end;
		end;
	end;
	if SettingData.ReadBool('Map_Sytem','Active_Next_Map',true) or SettingData.ReadBool('Map_Sytem','Active_Last_Map',true) then begin
		if MapSystem.TimeToStartVoting > 0 then begin
			MapSystem.TimeToStartVoting := MapSystem.TimeToStartVoting - 1;
			if MapSystem.TimeToStartVoting = 0 then begin
				case MapSystem.VoteType of
					1: Players.WriteConsole('Wait to start vote nextmap has expired.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
					2: Players.WriteConsole('Wait to start vote lastmap has expired.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
				end;
				MapSystem.VoteType := 0;
			end;
		end;
		if MapSystem.VoteTimeLeft > 0 then begin
			dec(MapSystem.VoteTimeLeft,1);
			if MapSystem.VoteTimeLeft = 0 then begin
				MapSystem.VoteType := 0;		MapSystem.VotedPlayersCount := 0;
				for i := 1 to 32 do Mapsystem.Voted[i] := false;
				Players.WriteConsole('Map vote failed.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
			end;
		end;
	end;
	if SettingData.ReadBool('Ping_Track','Active',true) then begin
		for i := 1 to 32 do if PlayerPingTrack[i].Count > 0 then begin
			dec(PlayerPingTrack[i].Count,1);	inc(PlayerPingTrack[i].Sum,Players[i].Ping);
			if Players[i].Ping > PlayerPingTrack[i].Max then PlayerPingTrack[i].Max := Players[i].Ping;
			if PlayerPingTrack[i].Count = 0 then Players.WriteConsole('Tracking result for '+Players[i].Name+': Average Ping: '+inttostr(Round(PlayerPingTrack[i].Sum/(SettingData.ReadInteger('Ping_Track','Measurement_Time',5)+1)))+', Max Ping: '+inttostr(PlayerPingTrack[i].Max),SettingData.ReadInteger('Ping_Track','Color_Good',$00BFFF));
		end;
	end;
	if SettingData.ReadBool('Average_Server_Ping','Active',true) then begin
		if Ticks mod (3600 * SettingData.ReadInteger('Average_Server_Ping','Time_Delay',6)) = 0 then begin
			for i := 1 to 32 do if (Players[i].Active) and (Players[i].Human) then SumPings := SumPings + Players[i].Ping;
			if Game.NumPlayers - Game.NumBots > 0 then begin
				AveragePing := Round(SumPings / (Game.NumPlayers - Game.NumBots));
				Players.WriteConsole('Recent average server ping is: '+inttostr(AveragePing)+'ms.', SettingData.ReadInteger('Average_Server_Ping','Color_Good',$00BFFF));
			end;
		end;
	end;
	if SettingData.ReadBool('Spec_Idle','Active',true) then begin
		for i := 1 to 32 do if Players[i].Active then begin
			if SettingData.ReadBool('Spec_Idle','Ignore_Admins',true) then if Players[i].IsAdmin then continue;
			if spec_time[i] > 0 then begin
				dec(spec_time[i], 1);
				if (spec_time[i] mod 60 = 0) and (spec_time[i] >= 60) then begin
					Players[i].WriteConsole('You cannot idle as spectator forever!', SettingData.ReadInteger('Spec_Idle','Color_Good',$00BFFF));
					Players[i].WriteConsole('Time left: ' + inttostr(spec_time[i] / 60) + iif(spec_time[i] = 60, ' minute', ' minutes'), SettingData.ReadInteger('Spec_Idle','Color_Good',$00BFFF));
				end else if spec_time[i] = 15 then begin
					Players[i].WriteConsole('--- FINAL WARNING ---', SettingData.ReadInteger('Spec_Idle','Color_Other',$00BFFF));
					Players[i].WriteConsole('Time left: 15 seconds', SettingData.ReadInteger('Spec_Idle','Color_Other',$00BFFF));
				end else if spec_time[i] = 0 then begin
					if SettingData.ReadInteger('Spec_Idle','Ban_Time',1) > 0 then begin
						Players.WriteConsole(Players[i].Name+' has been kicked for occupying', SettingData.ReadInteger('Spec_Idle','Color_Bad',$ff0033));
						Players.WriteConsole('a slot (banned for '+inttostr(SettingData.ReadInteger('Spec_Idle','Ban_Time',1)) + iif(SettingData.ReadInteger('Spec_Idle','Ban_Time',1) = 1, ' minute', ' minutes') + ').', SettingData.ReadInteger('Spec_Idle','Color_Bad',$ff0033));
						Players[i].Ban(SettingData.ReadInteger('Spec_Idle','Ban_Time',1),'Spec idle kick');
					end else begin
						Players.WriteConsole(Players[i].Name+' has been kicked for occupying a slot.', SettingData.ReadInteger('Spec_Idle','Color_Bad',$ff0033));
						Players[i].Kick(TKickSilent);
					end;
				end;
			end;
		end;
	end;
end;

function Commands(Player: TActivePlayer; Text: string): Boolean;
var BanPlayerID, TempLen, i: byte; Time: integer; Piece: string; Res: TStringList;
begin
	if Player.IsAdmin then begin
		if SettingData.ReadBool('Commands_Admin','Active_Ban_Range',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Ban_Range','banr|banrange|bantime')+')', Text) then begin
				if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Ban_Range','banr|banrange|bantime')+') \d{1,2} ([0-9])+([mhdy]|mon) .*$', Text) then begin
					try
						BanPlayerID := strtoint(GetPieceSC3(text,' ', 1));
					except
					end;
					if (BanPlayerID < 1) or (BanPlayerID > 32) then begin
						Player.WriteConsole('The ID must be in the range 1-32.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
						exit;
					end;
					if not Players[BanPlayerID].Active then begin
						Player.WriteConsole('There is no such player on the server.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
						exit;
					end;
					Piece := GetPieceSC3(Text,' ',2);		TempLen := Length(Piece);
					try
						case Copy(Piece,TempLen,TempLen) of
							'm' : begin delete(Piece,TempLen,TempLen); Time := strtoint(Piece); end;
							'h' : begin delete(Piece,TempLen,TempLen); Time := strtoint(Piece) * 60; end;
							'd' : begin delete(Piece,TempLen,TempLen); Time := strtoint(Piece) * 1440; end;
							'y' : begin delete(Piece,TempLen,TempLen); Time := strtoint(Piece) * 525600; end;
							else if Copy(Piece,TempLen-2,TempLen) = 'mon' then begin
								delete(Piece,TempLen-2,TempLen); 
								Time := strtoint(Piece) * 43200;
							end;
						end;
					except
						Player.WriteConsole('Ban time is probably too large number..',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
						exit;
					end;
					if Time > 0 then begin
						if (SettingData.ReadInteger('Commands_Admin','Max_Ban_Time',129600) > 0) and (Time > SettingData.ReadInteger('Commands_Admin','Max_Ban_Time',129600)) then begin
							if SettingData.ReadBool('Commands_Admin','Auto_Change_Time_If_Too_Big',true) then begin
								Time := SettingData.ReadInteger('Commands_Admin','Max_Ban_Time',129600);
								Player.WriteConsole('The ban time is too long. We set it to '+SettingData.ReadString('Commands_Admin','Max_Ban_Time','129600')+' minutes.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
							end else
							begin
								Player.WriteConsole('The ban time is too long. The operation was aborted!',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
								exit;
							end;
						end;
						Piece := FullReason(Text,' ', 3);
						if ReplaceRegExpr(' ',Piece,'',false) <> '' then begin
							Players.WriteConsole('Player '+Players[BanPlayerID].Name+' has been banned for '+inttostr(Time)+' minutes! By: '+Player.Name,SettingData.ReadInteger('Commands_Admin','Color_Good',$00BFFF));
							Players.WriteConsole('Reason is: '+Piece,SettingData.ReadInteger('Commands_Admin','Color_Good',$00BFFF));
							WriteLn('Player '+Players[BanPlayerID].Name+' has been banned for '+inttostr(Time)+' minutes! By: '+Player.Name);
							WriteLn('Reason is: '+Piece);
							Players[BanPlayerID].WriteConsole(' ',$00BFFF);
							Players[BanPlayerID].WriteConsole(' ',$00BFFF);
							Players[BanPlayerID].WriteConsole(' ',$00BFFF);
							Players[BanPlayerID].WriteConsole(' ',$00BFFF);
							Players[BanPlayerID].WriteConsole(' ',$00BFFF);
							Players[BanPlayerID].WriteConsole(' ',$00BFFF);
							Players[BanPlayerID].WriteConsole('You`ve been banned as "'+Piece+'", on: '+inttostr(Time)+' minutes! By: '+Player.Name,SettingData.ReadInteger('Commands_Admin','Color_BAD',$ff0033));
							Players[BanPlayerID].WriteConsole('You`ve been banned as "'+Piece+'", on: '+inttostr(Time)+' minutes! By: '+Player.Name,SettingData.ReadInteger('Commands_Admin','Color_BAD',$ff0033));
							Players[BanPlayerID].WriteConsole('You`ve been banned as "'+Piece+'", on: '+inttostr(Time)+' minutes! By: '+Player.Name,SettingData.ReadInteger('Commands_Admin','Color_BAD',$ff0033));
							Players[BanPlayerID].Ban(Time, Piece);
							exit;
						end else Player.WriteConsole('You probably didn`t give a reason.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					end else Player.WriteConsole('Time must be greater than 0.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
				end else
				begin
					try
						Res := File.CreateStringList;
						SplitRegExpr(QuoteRegExprMetaChars('|'), SettingData.ReadString('Commands_Admin','Commands_Ban_Range','banr|banrange|bantime'), Res);
						if Res.Count > 0 then begin
							Player.WriteConsole('Use correctly: /'+Res[Random(0,Res.Count)]+' <Player_ID> <Ban_Time> <Reason>',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
							Player.WriteConsole('Ban time format, example: 262800m or 4380h or 182d or 6mon or 1y',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
						end else
						begin
							Player.WriteConsole('Use correctly: /banr <Player_ID> <Ban_Time> <Reason>',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
							Player.WriteConsole('Ban time format, example: 262800m or 4380h or 182d or 6mon or 1y',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
						end;
					except
					finally
						Res.Free;
					end;
				end;
				exit;
			end;
		end;
		Text := lowercase(Text);
		if SettingData.ReadBool('Commands_Admin','Active_Admin_Commands',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Admin_Commands','admincommands')+')$',Text) then begin
				if AdminCommandsList.Count > 0 then begin
					if SettingData.ReadBool('Commands_Admin','Admin_Commands_List_Color_Identify',false) then begin
						for i := 0 to AdminCommandsList.Count-1 do begin
							try
								Player.WriteConsole(GetPieceSC3(AdminCommandsList[i],#9,1),strtoint(GetPieceSC3(AdminCommandsList[i],#9,0)));
							except
								Player.WriteConsole('Show admin commands list, error!', SettingData.ReadInteger('Commands_Admin','Color_Basic_Bad',$ff0033));
								exit;
							end;
						end;
					end else for i := 0 to AdminCommandsList.Count-1 do Player.WriteConsole(AdminCommandsList[i]+'                                                                                                      ', SettingData.ReadInteger('Commands_List','Color_Basic_Good',$00BFFF));
				end else Player.WriteConsole('There are no admin commands to display',SettingData.ReadInteger('Commands_Admin','Color_Basic_Bad',$ff0033));
				exit;
			end;
		end;
		if SettingData.ReadBool('Commands_Admin','Active_Randomize',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Randomize_Maps','randomize')+')$',Text) then begin
				MixMapList();
				Player.WriteConsole('Mapslist has been randomize.',SettingData.ReadInteger('Commands_Admin','Color_Good',$00BFFF));
				exit;
			end;
		end;
		if SettingData.ReadBool('Commands_Admin','Active_Reload_Settings',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Reload_Settings','reloadsettings')+')$',Text) then begin
				SettingData.Free;
				if File.Exists(Script.Dir+'\data\settings.ini') then SettingData := File.CreateINI(Script.Dir+'\data\settings.ini') else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+Script.Dir+'\data\settings.ini'+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',$ff0033);
					Script.Unload;
					exit;
				end;
				CommandsList.Free;
				if File.Exists(SettingData.ReadString('Paths','Commands_List',Script.Dir+'\data\Commands.txt')) then CommandsList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Commands_List',Script.Dir+'\data\Commands.txt')) else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Commands_List',Script.Dir+'\data\Commands.txt')+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					Script.Unload;
					exit;
				end;
				AdminCommandsList.Free;
				if File.Exists(SettingData.ReadString('Paths','Admin_Commands',Script.Dir+'\data\Admins_Commands.txt')) then AdminCommandsList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Admin_Commands',Script.Dir+'\data\Admins_Commands.txt')) else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Admin_Commands',Script.Dir+'\data\Admins_Commands.txt')+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					Script.Unload;
					exit;
				end;
				RulesList.Free;
				if File.Exists(SettingData.ReadString('Paths','Rules',Script.Dir+'\data\Rules.txt')) then RulesList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Rules',Script.Dir+'\data\Rules.txt')) else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Rules',Script.Dir+'\data\Rules.txt')+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					Script.Unload;
					exit;
				end;
				SpreeList.Free;
				if File.Exists(SettingData.ReadString('Paths','Spree_Messages',Script.Dir+'\data\Spree_Messages.txt')) then SpreeList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Spree_Messages',Script.Dir+'\data\Spree_Messages.txt')) else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Spree_Messages',Script.Dir+'\data\Spree_Messages.txt')+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					Script.Unload;
					exit;
				end;
				AdminsHWIDList.Free;
				if File.Exists(SettingData.ReadString('Paths','Admins_HWID_List',Script.Dir+'\data\Admins_HWID.txt')) then AdminsHWIDList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Admins_HWID_List',Script.Dir+'\data\Admins_HWID.txt')) else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Admins_HWID_List',Script.Dir+'\data\Admins_HWID.txt')+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					Script.Unload;
					exit;
				end;
				MapsForDisplayList.Free;
				if File.Exists(SettingData.ReadString('Paths','Maps_List','mapslist.txt')) then begin
					MapsForDisplayList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
					Game.LoadList(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
				end else
				begin
					Player.WriteConsole(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Maps_List','mapslist.txt')+'".',$ff0033);
					Player.WriteConsole(' [*] '+Script.Name+' -> The script has been disabled.',SettingData.ReadInteger('Commands_Admin','Color_Bad',$ff0033));
					Script.Unload;
					exit;
				end;
				Player.WriteConsole('Settings loaded successfully!',SettingData.ReadInteger('Commands_Admin','Color_Good',$00BFFF));
				exit;
			end;
		end;
		if SettingData.ReadBool('Commands_Admin','Active_Kill_All',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Kill_All','killall')+')$',Text) then for i := 0 to Players.Active.Count - 1 do if Players.Active[i].ID <> Player.ID then Players.Active[i].Damage(Players.Active[i].ID,Player.health*4);
		end;
		if SettingData.ReadBool('Commands_Admin','Active_Kick_All',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Kick_All','kickall')+')$',Text) then for i := 1 to 32 do if (Players[i].Active) and (i <> Player.ID) then Players[i].Kick(TKickSilent);
		end;
		if SettingData.ReadBool('Commands_Admin','Active_Explode_All',true) then begin
			if ExecRegExpr('^/('+SettingData.ReadString('Commands_Admin','Commands_Explode_All','explodeall')+')$',Text) then for i := 0 to Players.Active.Count - 1 do if (Players.Active[i].ID <> Player.ID) and (Players.Active[i].Alive) then Map.CreateBullet(Players.Active[i].X, Players.Active[i].Y, 0, 0, 1000, 4, Players.Active[i]);
		end;
	end;
	Result := false;
end;

procedure OnTCPMessage(Ip: string; Port: Word; Text: string);
begin
	if SettingData.ReadBool('Whoisadmin','Active',true) then begin
		if (SettingData.ReadBool('Whoisadmin','Count_TCP',true)) and (WhoisAdminTimer > 0) and (Copy(Text, 1, 1) = '[') and (Copy(Text, 3, 1) = ']') then AdminsList.Append(Text);
	end;
end;

procedure Speak(Player: TActivePlayer; Text: string);
var i: byte; FoundID: integer; VotePrecent, KD: double; TempString: string; TempSettingsINI: TIniFile; 
begin
	Text := lowercase(Text);
	//CommandsList
	if SettingData.ReadBool('Commands_List','Active',true) then begin
		if ExecRegExpr('^!('+SettingData.ReadString('Commands_List','Commands','cmd|cmds|command|commands')+')$',Text) then begin
			if CommandsList.Count > 0 then begin
				if SettingData.ReadBool('Commands_List','Color_Identify',false) then begin
					for i := 0 to CommandsList.Count-1 do begin
						try
							Player.WriteConsole(GetPieceSC3(CommandsList[i],#9,1),strtoint(GetPieceSC3(CommandsList[i],#9,0)));
						except
							Player.WriteConsole('Show commands list, error!', SettingData.ReadInteger('Commands_List','Color_Basic_Bad',$ff0033));
							exit;
						end;
					end;
				end else for i := 0 to CommandsList.Count-1 do Player.WriteConsole(CommandsList[i]+'                                                                                                      ', SettingData.ReadInteger('Commands_List','Color_Basic_Good',$00BFFF));
			end else Player.WriteConsole('There are no commands to display',SettingData.ReadInteger('Commands_List','Color_Basic_Bad',$ff0033));
			exit;
		end;
	end;
	//MapSystem
	if SettingData.ReadBool('Map_Sytem','Active_Next_Map',true) then begin
		if ExecRegExpr('^!('+SettingData.ReadString('Map_Sytem','Commands_Next_Map','n|nm|nextmap|whatisnextmap')+')$',Text) then begin
			if MapSystem.VoteTimeLeft = 0 then begin
				if MapSystem.VoteType = 0 then begin
					MapSystem.VoteType := 1;  MapSystem.TimeToStartVoting := SettingData.ReadInteger('Map_Sytem','Time_To_Start_And_Vote_Time_Add',7);
					Players.WriteConsole('Nextmap is: '+Game.Nextmap, SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
					Players.WriteConsole('To start voting for nextmap, type !vote within '+SettingData.ReadString('Map_Sytem','Time_To_Start_And_Vote_Time_Add','7')+' seconds.', SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
				end else
				begin
					case MapSystem.VoteType of
						1:	begin
								Player.WriteConsole('Currently waiting for start voting for nextmap: '+Game.Nextmap+' ('+inttostr(MapSystem.TimeToStartVoting)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
								Player.WriteConsole('To start voting for lastmap, type !vote within '+SettingData.ReadString('Map_Sytem','Time_To_Start_And_Vote_Time_Add','7')+' seconds.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							end;
						2:	begin
								Player.WriteConsole('Currently waiting for start voting for lastmap: '+MapSystem.Lastmap+' ('+inttostr(MapSystem.TimeToStartVoting)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
								Player.WriteConsole('To start voting for lastmap, type !vote within '+SettingData.ReadString('Map_Sytem','Time_To_Start_And_Vote_Time_Add','7')+' seconds.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							end;
					end;
				end;
			end else
			begin
				case MapSystem.VoteType of
					1:	begin
							Player.WriteConsole('Currently underway voting for nextmap: '+Game.Nextmap+' ('+inttostr(MapSystem.VoteTimeLeft)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							Player.WriteConsole('Type !vote to vote to change the map.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
						end;
					2: 	begin
							Player.WriteConsole('Currently underway voting for lastmap: '+MapSystem.Lastmap+' ('+inttostr(MapSystem.VoteTimeLeft)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							Player.WriteConsole('Type !vote to vote to change the map.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
						end;
				end;
			end;
			exit;
		end;
	end;
	if SettingData.ReadBool('Map_Sytem','Active_Last_Map',true) then begin
		if ExecRegExpr('^!('+SettingData.ReadString('Map_Sytem','Commands_Last_Map','l|lastmap|whatislastmap')+')$',Text) then begin
			if MapSystem.VoteTimeLeft = 0 then begin
				if MapSystem.VoteType = 0 then begin
					MapSystem.VoteType := 2;  MapSystem.TimeToStartVoting := SettingData.ReadInteger('Map_Sytem','Time_To_Start_And_Vote_Time_Add',7);
					Players.WriteConsole('Lastmap is: '+MapSystem.Lastmap, SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
					Players.WriteConsole('To start voting for lastmap, type !vote within '+SettingData.ReadString('Map_Sytem','Time_To_Start_And_Vote_Time_Add','7')+' seconds.', SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
				end else
				begin
					case MapSystem.VoteType of
						1:	begin
								Player.WriteConsole('Currently waiting for start voting for nextmap: '+Game.Nextmap+' ('+inttostr(MapSystem.TimeToStartVoting)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
								Player.WriteConsole('To start voting for lastmap, type !vote within '+SettingData.ReadString('Map_Sytem','Time_To_Start_And_Vote_Time_Add','7')+' seconds.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							end;
						2:	begin
								Player.WriteConsole('Currently waiting for start voting for lastmap: '+MapSystem.Lastmap+' ('+inttostr(MapSystem.TimeToStartVoting)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
								Player.WriteConsole('To start voting for lastmap, type !vote within '+SettingData.ReadString('Map_Sytem','Time_To_Start_And_Vote_Time_Add','7')+' seconds.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							end;
					end;
				end;
			end else
			begin
				case MapSystem.VoteType of
					1:	begin
							Player.WriteConsole('Currently underway voting for nextmap: '+Game.Nextmap+' ('+inttostr(MapSystem.VoteTimeLeft)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							Player.WriteConsole('Type !vote to vote to change the map.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
						end;
					2: 	begin
							Player.WriteConsole('Currently underway voting for lastmap: '+MapSystem.Lastmap+' ('+inttostr(MapSystem.VoteTimeLeft)+'s left)', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
							Player.WriteConsole('Type !vote to vote to change the map.', SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
						end;
				end;
			end;
			exit;
		end;
	end;
	if SettingData.ReadBool('Map_Sytem','Active_Next_Map',true) or SettingData.ReadBool('Map_Sytem','Active_Last_Map',true) then begin
		if ExecRegExpr('^!('+SettingData.ReadString('Map_Sytem','Commands_Vote','v|vote|votenext|votenextmap|nextmapvote')+')$',Text) then begin
			if not Mapsystem.Voted[Player.ID] then begin
				if MapSystem.VoteTimeLeft > 0 then inc(MapSystem.VoteTimeLeft,SettingData.ReadInteger('Map_Sytem','Time_To_Start_And_Vote_Time_Add',7)) else MapSystem.VoteTimeLeft := SettingData.ReadInteger('Map_Sytem','Vote_Time_Limit',30);
				Mapsystem.Voted[Player.ID] := true;
				inc(MapSystem.VotedPlayersCount,1);
				VotePrecent := single(100 * MapSystem.VotedPlayersCount) / single(Game.NumPlayers-iif(SettingData.ReadBool('Map_Sytem','Bots_Can_Vote',false),Game.NumBots,0));
				if MapSystem.TimeToStartVoting > 0 then begin
					MapSystem.TimeToStartVoting := 0;
					case MapSystem.VoteType of
						1: Players.WriteConsole(Player.Name+' started voting for the nextmap. ('+Game.Nextmap+')',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
						2: Players.WriteConsole(Player.Name+' started voting for the previous map. ('+MapSystem.Lastmap+')',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
					end;
				end else if MapSystem.VoteType = 0 then begin
					MapSystem.VoteType := 1;
					Player.WriteConsole('You have not specified what type of voting you want to choose.',SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
					Player.WriteConsole('Before write !vote, enter !lastmap or !nextmap. We automatic chose the vote for nextmap.',SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
					Players.WriteConsole(Player.Name+' started voting for the nextmap. ('+Game.Nextmap+')',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
				end;
				if VotePrecent >= SettingData.ReadInteger('Map_Sytem','Min_Vote_Precent_To_Change',65) then begin
					case MapSystem.VoteType of 
						1: begin Map.Nextmap;	Players.WriteConsole('Nextmap vote passed.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF)); end;
						2: begin Map.SetMap(MapSystem.Lastmap);		Players.WriteConsole('Lastmap vote passed.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF)); end;
					end;
					MapSystem.VoteType := 0;		MapSystem.VoteTimeLeft := 0;		MapSystem.VotedPlayersCount := 0;
					for i := 1 to 32 do Mapsystem.Voted[i] := false;
				end else Players.WriteConsole('Voting percentage of needed people: '+FormatFloat('0',VotePrecent)+'% / '+SettingData.ReadString('Map_Sytem','Min_Vote_Precent_To_Change','65')+'%.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
			end else Players.WriteConsole('You have already voted.',SettingData.ReadInteger('Map_Sytem','Color_Bad',$ff0033));
			exit;
		end;
	end;
	//Ratio
	if SettingData.ReadBool('Ratio','Active',true) then if ExecRegExpr('(^!+(('+SettingData.ReadString('Ratio','Commands','rate|ratio|kd|k/d|kdratio')+')+ .*))|(^!+('+SettingData.ReadString('Ratio','Commands','rate|ratio|kd|k/d|kdratio')+'))$',Text) then begin
		TempString := GetPieceSC3(Text,' ',1);
		if TempString <> '' then FoundID := FindPlayer(TempString) else FoundID := Player.ID;
		if FoundID = -1 then Player.WriteConsole('Player not found ('+TempString+')',SettingData.ReadInteger('Ratio','Color_Bad',$ff0033)) else begin
			if Players[FoundID].Team <> 5 then begin
				if Players[FoundID].Deaths = 0 then begin
					Players.WriteConsole(Players[FoundID].Name+' - K/D is incalculable ('+inttostr(Players[FoundID].Kills)+'/0) with '+inttostr(Players[FoundID].Flags)+' caps.',SettingData.ReadInteger('Ratio','Color_Bad',$ff0033));
					exit;
				end else
				begin
					KD := single(Players[FoundID].Kills)/Players[FoundID].Deaths;
					Players.WriteConsole(Players[FoundID].Name+' - K/D is '+FormatFloat('0.00',KD)+' ('+inttostr(Players[FoundID].Kills)+'/'+inttostr(Players[FoundID].Deaths)+') with '+inttostr(Players[FoundID].Flags)+' caps.',SettingData.ReadInteger('Ratio','Color_Good',$00BFFF));
				end;
			end else Players.WriteConsole(Players[FoundID].Name+' - is the spectating',SettingData.ReadInteger('Ratio','Color_Bad',$ff0033));
		end;
		exit;
	end;
	//PingTrack
	if SettingData.ReadBool('Ping_Track','Active',true) then begin
		if ExecRegExpr('(^!+(('+SettingData.ReadString('Ping_Track','Commands','t|track|pingtrack|trackping')+')+ .*))|(^!+('+SettingData.ReadString('Ping_Track','Commands','t|track|pingtrack|trackping')+'))$',Text) then begin
			TempString := GetPieceSC3(Text,' ',1);
			if TempString <> '' then FoundID := FindPlayer(TempString) else FoundID := Player.ID;
			if FoundID = -1 then Player.WriteConsole('Player not found ('+TempString+')',SettingData.ReadInteger('Ping_Track','Color_Bad',$ff0033)) else begin
				if PlayerPingTrack[FoundID].Count > 0 then Player.WriteConsole(Players[FoundID].Name+' is already tracking.',SettingData.ReadInteger('Ping_Track','Color_Bad',$ff0033)) else begin
					PlayerPingTrack[FoundID].Count := SettingData.ReadInteger('Ping_Track','Measurement_Time',5);
					Player.WriteConsole('Tracking '+Players[FoundID].Name+' ...',SettingData.ReadInteger('Ping_Track','Color_Good',$00BFFF));
					PlayerPingTrack[FoundID].Max := Players[FoundID].Ping;
					PlayerPingTrack[FoundID].Sum := PlayerPingTrack[FoundID].Max;
				end;
			end;
			exit;
		end;
	end;
	//WhoisAdmin
	if SettingData.ReadBool('Whoisadmin','Active',true) then begin
		if ExecRegExpr('^!('+SettingData.ReadString('Whoisadmin','Commands','whoisadmin|adminlist|adminsonline|onlineadmins|onlineadmin|adminonline|whois')+')$',Text) then if WhoisAdminTimer = 0 then begin
			Players.WriteConsole('Counting connected admins...', SettingData.ReadInteger('Whoisadmin','Color_Good',$00BFFF));
			Players.WriteConsole(' ', $00BFFF);
			Players.WriteConsole(' ', $00BFFF);
			WhoisAdminTimer := SettingData.ReadInteger('Whoisadmin','Time_Counting',3);
			if SettingData.ReadBool('Whoisadmin','Count_TCP',true) then WriteLn('/clientlist (127.0.0.1)');
			exit;
		end else Players.WriteConsole('Already counting connected admins - please wait...', SettingData.ReadInteger('Whoisadmin','Color_Bad',$ff0033));
	end;
	//Mapsystem
	if SettingData.ReadBool('Map_Sytem','Active_Current_Map',true) then if ExecRegExpr('^!('+SettingData.ReadString('Map_Sytem','Commands_Map','map|current|currentmap|mapcurrent|whatismap')+')$',Text) then begin
		Players.WriteConsole('Current map is: '+Game.CurrentMap, SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
		exit;
	end;
	//Maplist
	if SettingData.ReadBool('Maps_Lists','Active',true) then if ExecRegExpr('^!('+SettingData.ReadString('Maps_Lists','Commands','maps|mapslist|listmap|listmaps|maplist')+')$',Text) then begin
		DisplayArrayTables(MapsForDisplayList, SettingData.ReadInteger('Maps_Lists','Number_Of_Rows',5), SettingData.ReadBool('Maps_Lists','Decrease_Text',true), SettingData.ReadBool('Maps_Lists','Sorting',false), SettingData.ReadBool('Maps_Lists','Display_For_All',false), SettingData.ReadInteger('Maps_Lists','Color_Good',$00BFFF), Player);
		exit;
	end;
	//ShowRules
	if SettingData.ReadBool('Rules','Active',true) then if ExecRegExpr('^!('+SettingData.ReadString('Rules','Commands','rules|rules|rul')+')$',Text) then begin
		if RulesList.Count > 0 then begin
			ShowRules(Player);
			exit;
		end else Player.WriteConsole('No rules to display.', SettingData.ReadInteger('Rules','Color_Basic_Bad',$ff0033));
	end;
	//Ping
	if SettingData.ReadBool('Ping','Active',true) then if ExecRegExpr('(^!+(('+SettingData.ReadString('Ping','Commands','ping|p')+')+ .*))|(^!+('+SettingData.ReadString('Ping','Commands','ping|p')+'))$',Text) then begin
		TempString := GetPieceSC3(Text,' ',1);
		if TempString <> '' then FoundID := FindPlayer(TempString) else FoundID := Player.ID;
		if FoundID = -1 then Player.WriteConsole('Player not found ('+TempString+')',SettingData.ReadInteger('Ratio','Color_Bad',$ff0033)) else Players.WriteConsole(Player.Name+'`s ping: '+IntToStr(Player.Ping), SettingData.ReadInteger('Ping','Color_Good',$00BFFF));
		exit;
	end;
	//Time
	if SettingData.ReadBool('Time','Active',true) then if ExecRegExpr('^!('+SettingData.ReadString('Time','Commands','time|date')+')$',Text) then begin
		Players.WriteConsole('Time on the server - '+FormatDateTime('dd.mm.yyyy - h:nn:ss',Now()), SettingData.ReadInteger('Time','Color_Good',$00BFFF));
		exit;
	end;
	//ChangeTeam
	if SettingData.ReadBool('Change_Team','Active',true) then begin
		if SettingData.ReadBool('Change_Team','Active_Join_Specator',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join_Specator','5|s|spec|specators|joins|join s')+')$',Text) then begin
			TempSettingsINI := File.CreateINI(Script.Dir+'/soldat.ini');
			if Game.Spectators < TempSettingsINI.ReadInteger('NETWORK', 'Max_Spectators',2) then Player.ChangeTeam(5, TJoinSilent) else Player.WriteConsole('Specators is full!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
			TempSettingsINI.Free;
		end;
		if (Game.GameStyle = 3) or (Game.GameStyle = 4) or (Game.GameStyle = 5) or (Game.GameStyle = 6) then begin
			if SettingData.ReadBool('Change_Team','Active_Join',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join','j|join|start|play')+')$',Text) then begin
				if Player.Team = 5 then begin
					if Game.Teams[1].Count < Game.Teams[2].Count then Player.ChangeTeam(1, TJoinSilent) else if Game.Teams[1].Count > Game.Teams[2].Count then Player.ChangeTeam(2, TJoinSilent) else Player.ChangeTeam(Random(1,3), TJoinSilent);
				end else Player.WriteConsole('You are already in the team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				exit;
			end;
			if SettingData.ReadBool('Change_Team','Active_Join_Alpha',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join_Alpha','1|a|alpha|red|r|joina|join a')+')$',Text) then begin
				if Player.Team <> 1 then begin
					if Game.Teams[1].Count < Game.Teams[Player.Team].Count then Player.ChangeTeam(1, TJoinSilent) else Player.WriteConsole('Anty unbalance teams - You can`t now join to alpha team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				end else Player.WriteConsole('You are already in the alpha team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				exit;
			end;
			if SettingData.ReadBool('Change_Team','Active_Join_Bravo',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join_Bravo','2|b|bravo|blue|blu|joinb|join b')+')$',Text) then begin
				if Player.Team <> 2 then begin
					if Game.Teams[2].Count < Game.Teams[Player.Team].Count then Player.ChangeTeam(2, TJoinSilent) else Player.WriteConsole('Anty unbalance teams - You can`t now join to bravo team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				end else Player.WriteConsole('You are already in the bravo team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				exit;
			end;
		end else if Game.GameStyle = 4 then begin
			if SettingData.ReadBool('Change_Team','Active_Join_Charlie',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join_Charlie','3|c|char|charlie|yellow|yel|joinc|join c')+')$',Text) then begin
				if Player.Team <> 3 then begin
					if Game.Teams[3].Count < Game.Teams[Player.Team].Count then Player.ChangeTeam(3, TJoinSilent) else Player.WriteConsole('Anty unbalance teams - You can`t now join to charlie team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				end else Player.WriteConsole('You are already in the charlie team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				exit;
			end;
			if SettingData.ReadBool('Change_Team','Active_Join_Delta',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join_Delta','4|d|del|delta|green|gre|joind|join d')+')$',Text) then begin
				if Player.Team <> 4 then begin
					if Game.Teams[4].Count < Game.Teams[Player.Team].Count then Player.ChangeTeam(4, TJoinSilent) else Player.WriteConsole('Anty unbalance teams - You can`t now join to delta team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				end else Player.WriteConsole('You are already in the delta team!',SettingData.ReadInteger('Change_Team','Color_Bad',$ff0033));
				exit;
			end;
		end else if SettingData.ReadBool('Change_Team','Active_Join',true) then if ExecRegExpr('^!('+SettingData.ReadString('Change_Team','Commands_Join','j|join|start|play')+')$',Text) then Player.ChangeTeam(0, TJoinSilent);
	end;
end;

procedure JoinG(Player: TActivePlayer; Team: TTeam);
var i: integer;
begin
	for i := 0 to AdminsHWIDList.Count - 1 do if  AdminsHWIDList[i] = Player.HWID then begin
		Player.IsAdmin := true;
		exit;
	end;
end;

procedure JoinT(Player: TActivePlayer; Team: TTeam);
begin
	if Team.ID = 5 then begin
		if SettingData.ReadBool('Spec_Idle','Ignore_Admins',true) then if Player.IsAdmin then exit;;
		if SettingData.ReadBool('Spec_Idle','Active',true) then begin
			if Player.Human then begin
				Spec_Time[Player.ID] := SettingData.ReadInteger('Spec_Idle','Spec_Max_Time',10) * 60;
				Player.WriteConsole('Remember, you cannot idle as spectator forever!', SettingData.ReadInteger('Spec_Idle','Color_Good',$00BFFF));
				Player.WriteConsole('If you won''t leave or join any team,', SettingData.ReadInteger('Spec_Idle','Color_Good',$00BFFF));
				Player.WriteConsole('you will be kicked per '+SettingData.ReadString('Spec_Idle','Spec_Max_Time','10') + iif(SettingData.ReadInteger('Spec_Idle','Spec_Max_Time',10) = 1, ' minute.', ' minutes.'), SettingData.ReadInteger('Spec_Idle','Color_Good',$00BFFF));
			end;
		end;
	end else Spec_Time[Player.ID] := -1;
end;

function CalcSpree(Spree: Integer): Integer;
var TempInt: Integer;
begin
	TempInt := Spree div SettingData.ReadInteger('Killing_Spree','Number_Spree_Between_Messages',4);
	if SpreeList.Count < TempInt then Result := -1 else Result := TempInt-1;
end;

procedure OnKill(Killer, Victim: TActivePlayer; BulletId: Byte);
var i: byte; MessageID: Integer; 
begin
	if SettingData.ReadBool('Killing_Spree','Active',true) then begin
		if (SettingData.ReadBool('Killing_Spree','Counts_Bots',true) = false) and ((Killer.Human = false) or (Victim.Human = false)) then exit;
		if Killer.ID <> Victim.ID then begin
			Inc(Spree[Killer.ID], 1);
			if Spree[Victim.ID] >= SettingData.ReadInteger('Killing_Spree','Number_Spree_Between_Messages',4) then for i := 0 to Players.Active.Count - 1 do if Players.Active[i].ID <> Victim.ID then Players.Active[i].WriteConsole(Victim.Name+'''s '+inttostr(Spree[Victim.ID])+' killing spree has been ended by '+Killer.Name, SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5)) else Victim.WriteConsole('Your '+IntToStr(Spree[Victim.ID])+' killing spree has been ended by '+Killer.Name, SettingData.ReadInteger('Killing_Spree','Color_Bad',$FF0000));
			if Spree[Killer.ID] mod SettingData.ReadInteger('Killing_Spree','Number_Spree_Between_Messages',4) = 0 then begin
				MessageID := CalcSpree(Spree[Killer.ID]);
				for i := 0 to Players.Active.Count - 1 do if Players.Active[i].ID <> Killer.ID then begin
					if MessageID = -1 then Players.Active[i].WriteConsole('    '+Killer.Name+' is on a ['+IntToStr(Spree[Killer.ID])+'] Killing Spree!', SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5)) else Players.Active[i].WriteConsole('    '+Killer.Name+' '+SpreeList[MessageID]+' ['+IntToStr(Spree[Killer.ID])+']', SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5));
				end else
				begin
					if MessageID = -1 then Killer.WriteConsole('    '+Killer.Name+' is on a ['+IntToStr(Spree[Killer.ID])+'] Killing Spree!', SettingData.ReadInteger('Killing_Spree','Color_Good',$FFA500)) else Killer.WriteConsole('    '+Killer.Name+' '+SpreeList[MessageID]+' ['+IntToStr(Spree[Killer.ID])+']', SettingData.ReadInteger('Killing_Spree','Color_Good',$FFA500));
				end;
			end;
			Spree[Victim.ID] := 0;
		end else if not SettingData.ReadBool('Killing_Spree','Counts_Bots',true) then begin
			if Spree[Victim.ID] >= SettingData.ReadInteger('Killing_Spree','Number_Spree_Between_Messages',4) then begin
				for i := 0 to Players.Active.Count - 1 do if Players.Active[i].ID <> Victim.ID then begin
					Players.Active[i].WriteConsole(Victim.Name+'''s '+inttostr(Spree[Victim.ID])+' killing spree has been ended', SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5));
					Players.Active[i].WriteConsole('Player has killed himself', SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5));
				end else Victim.WriteConsole('Your '+IntToStr(Spree[Victim.ID])+' killing spree has been ended by yourself', SettingData.ReadInteger('Killing_Spree','Color_Bad',$FF0000));
			end;
			Spree[Victim.ID] := 0;
		end;
	end;
end;

procedure LeaveG(Player: TActivePlayer; Kicked: Boolean);
var i: byte;
begin
	//Spree
	if Spree[Player.ID] >= SettingData.ReadInteger('Killing_Spree','Number_Spree_Between_Messages',4) then begin
		Players.WriteConsole(Player.Name+'''s '+inttostr(Spree[Player.ID])+' killing spree has been ended', SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5));
		Players.WriteConsole('Player has left the game', SettingData.ReadInteger('Killing_Spree','Color_Other',$088DA5));
	end;
	Spree[Player.ID] := 0;
	//Voting System
	if Mapsystem.Voted[Player.ID] then begin
		Mapsystem.Voted[Player.ID] := false;
		MapSystem.VotedPlayersCount := MapSystem.VotedPlayersCount - 1;
	end;
	if Game.NumPlayers-1 > 1 then begin
		if (single(100 * MapSystem.VotedPlayersCount) / single(Game.NumPlayers-iif(SettingData.ReadBool('Map_Sytem','Bots_Can_Vote',false),Game.NumBots,0))) >= SettingData.ReadInteger('Map_Sytem','Min_Vote_Precent_To_Change',65) then begin
			case MapSystem.VoteType of 
				1: begin Map.Nextmap;	Players.WriteConsole('Nextmap vote passed.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF)); end;
				2: begin Map.SetMap(MapSystem.Lastmap);		Players.WriteConsole('Lastmap vote passed.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF)); end;
			end;
			MapSystem.VoteType := 0;		MapSystem.VoteTimeLeft := 0;		MapSystem.VotedPlayersCount := 0;
			for i := 1 to 32 do Mapsystem.Voted[i] := false;
		end;
	end else
	begin
		if MapSystem.VoteType > 0 then begin
			for i := 1 to 32 do begin
				Mapsystem.Voted[i] := false;
				if i <> Player.ID then Players[i].WriteConsole('You stayed alone! Voting was aborted.',SettingData.ReadInteger('Map_Sytem','Color_Good',$00BFFF));
			end;
			MapSystem.VoteType := 0;		MapSystem.VoteTimeLeft := 0;		MapSystem.VotedPlayersCount := 0;
		end;
	end;
	//Other
	Player.IsAdmin := false;	spec_time[Player.ID] := 0;
end;

procedure OnBeforeMapChange(Next: String);
var i: byte;
begin
	if Players.Active.Count > 0 then begin
		for i := 0 to Players.Active.Count - 1 do begin
			Spree[Players.Active[i].ID] := 0;
			Mapsystem.Voted[Players.Active[i].ID] := false;
		end;
	end;
	MapSystem.Lastmap := Game.CurrentMap;
	MapSystem.VoteType := 0;		MapSystem.VoteTimeLeft := 0;		MapSystem.VotedPlayersCount := 0;
end;

procedure OnAfterMapChange(NewMap: String);
var i: integer;
begin
	if SettingData.ReadBool('Rules','When_Map_Change_Display',true) then if RulesList.Count > 0 then for i := 1 to 32 do if Players[i].Active then ShowRules(Players[i]);
end;

procedure ScriptRecompile();
begin
	if File.Exists(Script.Dir+'\data\settings.ini') then SettingData := File.CreateINI(Script.Dir+'\data\settings.ini') else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+Script.Dir+'\data\settings.ini'+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	if File.Exists(SettingData.ReadString('Paths','Commands_List',Script.Dir+'\data\Commands.txt')) then CommandsList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Commands_List',Script.Dir+'\data\Commands.txt')) else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Commands_List',Script.Dir+'\data\Commands.txt')+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	if File.Exists(SettingData.ReadString('Paths','Admin_Commands',Script.Dir+'\data\Admins_Commands.txt')) then AdminCommandsList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Admin_Commands',Script.Dir+'\data\Admins_Commands.txt')) else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Admin_Commands',Script.Dir+'\data\Admins_Commands.txt')+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	if File.Exists(SettingData.ReadString('Paths','Rules',Script.Dir+'\data\Rules.txt')) then RulesList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Rules',Script.Dir+'\data\Rules.txt')) else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Rules',Script.Dir+'\data\Rules.txt')+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	if File.Exists(SettingData.ReadString('Paths','Spree_Messages',Script.Dir+'\data\Spree_Messages.txt')) then SpreeList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Spree_Messages',Script.Dir+'\data\Spree_Messages.txt')) else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Spree_Messages',Script.Dir+'\data\Spree_Messages.txt')+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	if File.Exists(SettingData.ReadString('Paths','Admins_HWID_List',Script.Dir+'\data\Admins_HWID.txt')) then AdminsHWIDList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Admins_HWID_List',Script.Dir+'\data\Admins_HWID.txt')) else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Admins_HWID_List',Script.Dir+'\data\Admins_HWID.txt')+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	if File.Exists(SettingData.ReadString('Paths','Maps_List','mapslist.txt')) then begin
		MapsForDisplayList := File.CreateStringListFromFile(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
		Game.LoadList(SettingData.ReadString('Paths','Maps_List','mapslist.txt'));
	end else
	begin
		WriteLN(' [*] '+Script.Name+' -> Error while loading file "'+SettingData.ReadString('Paths','Maps_List','mapslist.txt')+'".');
		WriteLN(' [*] '+Script.Name+' -> The script has been disabled.');
		Script.Unload;
		exit;
	end;
	WriteLn(' [*] '+Script.Name+' -> Settings loaded successfully!');
	MixMapList();
	MapSystem.Lastmap := Game.CurrentMap;
	AdminsList := File.CreateStringList;
	Players.WriteConsole('Basic v'+ScriptVer+' recompiled - successfully :)', $FFFFAA00);
end;

procedure ScriptDecl();
var i: byte;
begin
	for i := 1 to 32 do begin
		Players[i].OnCommand := @Commands;
		Players[i].OnSpeak := @Speak;
		Players[i].OnKill := @OnKill;
	end;
	Map.OnBeforeMapChange := @OnBeforeMapChange;
	Map.OnAfterMapChange := @OnAfterMapChange;
	Game.OnTCPMessage := @OnTCPMessage;
	Game.OnLeave := @LeaveG;
	Game.OnJoin := @JoinG;
	for i := 0 to 5 do Game.Teams[i].OnJoin := @JoinT;
	Game.OnClockTick := @Timers;
end;

initialization
begin
	ScriptDecl();
	ScriptRecompile();
end;

finalization;
end.