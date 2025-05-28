{
Logger by Hacktank
 /-------------------\
 |   Version 0.0.2   |
 \-------------------/
}
const
	mapmax=12;
	mkills=0;
	mdeaths=1;
	mselfkills=2;
	mflagcaps=3;
	mflaggrabs=4;
	mflagreturns=5;
	mmapplays=6;
	mplayerjoins=7;
	mplayerleaves=8;
	mplayerkicks=9;
	malphawins=10;
	mbravowins=11;
	
	playermax=6;
	pkills=0;
	pdeaths=1;
	pflaggrabs=2;
	pflagreturns=3;
	pflagcaps=4;
	pselfkills=5;

var
	mapdata: array[0..mapmax-1] of integer;
	playerdata: array[1..32] of array[0..playermax-1] of integer;
	prevmap: string;
	ascore,bscore: integer;
	compiled,survival,rfs,bfs: boolean;

function xsplit(const source: string; const delimiter: string):TStringArray;
var i,x,d:integer; s:string;
begin
d:=length(delimiter);x:=0;i:=1;SetArrayLength(Result,1);
while(i<=length(source)) do begin s:=Copy(source,i,d); if(s=delimiter) then begin inc(i,d); inc(x,1); SetArrayLength(result,x+1);
end else begin result[x]:= result[x]+Copy(s,1,1);inc(i,1); end; end;
end;

function XJoin(ary: array of string; splitter: string): string;
var i: integer;
begin
result := ary[0];
for i := 1 to getarraylength(ary)-1 do begin
	result := result+splitter+ary[i];
	end;
end;

function CharMultiply(char: string; times: variant): string;
var u: integer;
begin
result := '';
for u := 1 to round(times) do begin
	result := (result + char);
	end;
end;

procedure TextBox(ID: byte; inputraw: array of string; headline,ychar,xchar,corner: string; color: longint);
var i,max,divlength,allignlength: byte; divstyle,alligncontent,alligntype: string; input: array of string;
begin
max := length(headline);
input := inputraw;
for i := 0 to getarraylength(input)-1 do begin
	if getpiece(input[i],' ',0) = 'divline' then begin
		divlength := strtoint(getpiece(input[i],' ',2));
		divstyle := getpiece(input[i],' ',1);
		input[i] := charmultiply(' ',(max-divlength) div 2)+charmultiply(divstyle,divlength)+charmultiply(' ',(max-divlength) div 2);
		end;
	if length(input[i]) > max then max := length(input[i]);
	end;
for i := 0 to getarraylength(input)-1 do begin
	if ((getpiece(input[i],' ',0) = 'center') OR (getpiece(input[i],' ',0) = 'right') OR (getpiece(input[i],' ',0) = 'left')) then begin
		alligntype := getpiece(input[i],' ',0);
		alligncontent := getpiece(input[i],alligntype+' ',1);
		allignlength := length(alligncontent);
		if alligntype = 'center' then input[i] := charmultiply(' ',(max-allignlength) div 2)+alligncontent;
		if alligntype = 'right' then input[i] := charmultiply(' ',(max-allignlength))+alligncontent;
		if alligntype = 'left' then input[i] := alligncontent+charmultiply(' ',(max-allignlength));
		end;
	if length(input[i]) > max then max := length(input[i]);
	end;	
writeconsole(ID,corner+charmultiply(xchar,(max-length(headline)) div 2)+headline+charmultiply(xchar,(max-length(headline)+0.4) div 2)+corner,color);
for i := 0 to getarraylength(input)-1 do if input[i] <> '' then writeconsole(ID,ychar+input[i]+charmultiply(' ',max-length(input[i]))+ychar,color);
writeconsole(ID,corner+charmultiply(xchar,max)+corner,color);
end;

function BadCharByNum(Num: integer): string;
begin
result := '';
case num of
	0: result := '\';
	1: result := '/';
	2: result := ':';
	3: result := '*';
	4: result := '?';
	5: result := '"';
	6: result := '<';
	7: result := '>';
	8: result := '|';
	end;
end;

function SafeName(Name: string): string;
var still: boolean; i,temp: integer;
begin
result := name;
still := true;
while(still=true) do begin
	still := false;
	for i := 0 to 8 do begin
		if containsstring(name,badcharbynum(i)) then begin
			temp := pos(badcharbynum(i),name);
			delete(name,temp,1);
			still := true;
			end;
		end;
	end;
result := name;
end;

procedure LoadMap(NewMap: string);
var i: integer; tempdata: array of string;
begin
if fileexists('scripts/log/maps/'+newmap+'.txt') then begin
	tempdata := xsplit(readfile('scripts/log/maps/'+newmap+'.txt'),chr(13)+chr(10));
	for i := 0 to mapmax-1 do mapdata[i] := strtoint(tempdata[i]);
	end	else begin
		for i := 0 to mapmax-1 do mapdata[i] := 0;
		end;
end;

procedure SaveMap(MapName: string);
var i: integer; tempdata: array of string;
begin
setarraylength(tempdata,mapmax);
for i := 0 to mapmax-1 do tempdata[i] := inttostr(mapdata[i]);
writefile('scripts/log/maps/'+mapname+'.txt',xjoin(tempdata,chr(13)+chr(10)));
end;

procedure LoadPlayer(ID: byte);
var i: integer; tempdata: array of string;
begin
if getplayerstat(ID,'active') then begin
	if fileexists('scripts/log/players/'+safename(getplayerstat(ID,'name'))+'.txt') then begin
		tempdata := xsplit(readfile('scripts/log/players/'+safename(getplayerstat(ID,'name'))+'.txt'),chr(13)+chr(10));
		for i := 0 to playermax-1 do playerdata[ID][i] := strtoint(tempdata[i]);
		end	else begin
			for i := 0 to playermax-1 do playerdata[ID][i] := 0;
			end;
	end;
end;

procedure SavePlayer(ID: byte);
var i: integer; tempdata: array of string;
begin
if getplayerstat(ID,'active') then begin
	setarraylength(tempdata,playermax);
	for i := 0 to playermax-1 do tempdata[i] := inttostr(playerdata[ID][i]);
	writefile('scripts/log/players/'+safename(getplayerstat(ID,'name'))+'.txt',xjoin(tempdata,chr(13)+chr(10)));
	end;
end;

function IDByName(Name: string): byte;
var i: byte;
begin
result := 0;
for i := 1 to 32 do if getplayerstat(i,'active')=true then begin
	if containsstring(lowercase(getplayerstat(i,'name')),lowercase(name)) then begin
		result := i;
		break;
		end;
	end;
end;

function MapStatNameByNum(Num: byte): string;
begin
result := '';
case num of
	mkills: result := 'Kills';
	mdeaths: result := 'Deaths';
	mselfkills: result := 'Selfkills';
	mflagcaps: result := 'Flag Captures';
	mflaggrabs: result := 'Flag Grabs';
	mflagreturns: result := 'Flag Returns';
	mmapplays: result := 'Map Plays';
	mplayerjoins: result := 'Player Joins';
	mplayerleaves: result := 'Player Leaves';
	mplayerkicks: result := 'Player Kicks';
	malphawins: result := 'Alpha Wins';
	mbravowins: result := 'Bravo Wins';
	end;
end;

function MapStatNumByName(Name: string): byte;
var i: byte;
begin
result := -1;
for i := 1 to mapmax do	if containsstring(lowercase(mapstatnamebynum(i)),lowercase(name)) then result := i;
end;

function PlayerStatNameByNum(Num: byte): string;
begin
result := '';
case num of
	pkills: result := 'Kills';
	pdeaths: result := 'Deaths';
	pselfkills: result := 'Selfkills';
	pflagcaps: result := 'Flag Captures';
	pflaggrabs: result := 'Flag Grabs';
	pflagreturns: result := 'Flag Returns';
	end;
end;

function PlayerStatNumByName(Name: string): byte;
var i: byte;
begin
result := -1;
for i := 1 to mapmax do	if containsstring(lowercase(playerstatnamebynum(i)),lowercase(name)) then result := i;
end;

procedure ShowMapStats(ID: byte);
var mapstats: array of string;
begin
setarraylength(mapstats,16);
mapstats[0] := 'center -- '+prevmap+' --';
mapstats[1] := 'Kills -- '+inttostr(mapdata[mkills]);
mapstats[2] := 'Deaths -- '+inttostr(mapdata[mdeaths]);
mapstats[3] := 'Selfkills -- '+inttostr(mapdata[mselfkills]);
mapstats[4] := 'center -----';
mapstats[5] := 'Flag Caps -- '+inttostr(mapdata[mflagcaps]);
mapstats[6] := 'Flag Returns -- '+inttostr(mapdata[mflagreturns]);
mapstats[7] := 'Flag Grabs -- '+inttostr(mapdata[mflaggrabs]);
mapstats[8] := 'center -----';
mapstats[9] := 'Mapplays -- '+inttostr(mapdata[mmapplays]);
if ((gamestyle=3) OR (gamestyle=5)) then mapstats[10] := 'Alpha Wins -- '+inttostr(mapdata[malphawins]) else mapstats[10] := '';
if ((gamestyle=3) OR (gamestyle=5)) then mapstats[11] := 'Bravo Wins -- '+inttostr(mapdata[mbravowins]) else mapstats[11] := '';
mapstats[12] := 'center -----';
mapstats[13] := 'Players Joined -- '+inttostr(mapdata[mplayerjoins]);
mapstats[14] := 'Players Kicked -- '+inttostr(mapdata[mplayerkicks]);
mapstats[15] := 'Players Left -- '+inttostr(mapdata[mplayerleaves]);
textbox(ID,mapstats,' Map Stats ','|','_','+',$ff777777);
end;

procedure ShowPlayerStats(ID: byte; targetname: string);
var target: byte; playerstats: array of string;
begin
if targetname <> '' then target := idbyname(targetname) else target := ID;
if target = 0 then begin
	writeconsole(ID,'No name match found for '''+targetname+'',$ffaa6666);
	exit;
	end;
setarraylength(playerstats,8);
playerstats[0] := 'center -- '+getplayerstat(target,'name')+' --';
playerstats[1] := 'Kills -- '+inttostr(playerdata[target][pkills]);
playerstats[2] := 'Deaths -- '+inttostr(playerdata[target][pdeaths]);
playerstats[3] := 'Selfkills -- '+inttostr(playerdata[target][pselfkills]);
playerstats[4] := 'center -----';
playerstats[5] := 'Flag Caps -- '+inttostr(playerdata[target][pflagcaps]);
playerstats[6] := 'Flag Returns -- '+inttostr(playerdata[target][pflagreturns]);
playerstats[7] := 'Flag Grabs -- '+inttostr(playerdata[target][pflaggrabs]);
textbox(ID,playerstats,' Player Stats ','|','_','+',$ff777777);
end;

procedure OnCompile();
begin
loadmap(currentmap);
survival := iif(readini('soldat.ini','GAME','Survival_Mode','0')='1',true,false);
compiled := true;
end;

procedure ActivateServer();
begin
oncompile();
end;

procedure AppOnIdle(Ticks: integer);
begin
if not compiled then oncompile();
if timeleft > 0 then begin
	ascore := alphascore;
	bscore := bravoscore;
	end;
end;

procedure OnMapChange(NewMap: String);
var i: byte;
begin
for i:= 1 to 32 do if getplayerstat(i,'active') then saveplayer(i);
writeln('alpha='+inttostr(ascore)+'  bravo='+inttostr(bscore));
if prevmap <> '' then begin
	mapdata[mmapplays] := mapdata[mmapplays] + 1;
	if ascore > bscore then mapdata[malphawins] := mapdata[malphawins] + 1;
	if bscore > ascore then mapdata[mbravowins] := mapdata[mbravowins] + 1;
	savemap(prevmap);
	end;
loadmap(newmap);
prevmap := newmap;
bscore := 0;
ascore := 0;
end;

procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
if getpiece(text,' ',0) = '!mapstats' then showmapstats(ID);
if getpiece(text,' ',0) = '!stats' then showplayerstats(ID,getpiece(text,getpiece(text,' ',0)+' ',1));
end;

procedure OnJoinGame(ID, Team: byte);
begin
if getplayerstat(ID,'human') then begin
	mapdata[mplayerjoins] := mapdata[mplayerjoins] + 1;
	loadplayer(ID);
	end;
end;

procedure OnLeaveGame(ID, Team: byte;Kicked: boolean);
begin
if getplayerstat(ID,'human') then begin
	if kicked then mapdata[mplayerkicks] := mapdata[mplayerkicks] + 1 else mapdata[mplayerleaves] := mapdata[mplayerleaves] + 1;
	saveplayer(ID);
	end;
end;

procedure OnFlagGrab(ID, TeamFlag: byte;GrabbedInBase: boolean);
begin
mapdata[mflaggrabs] := mapdata[mflaggrabs] + 1;
if getplayerstat(ID,'human') then playerdata[ID][pflaggrabs] := playerdata[ID][pflaggrabs] + 1;
case teamflag of
	1: rfs := false;
	2: bfs := false;
	end;
end;

procedure OnFlagReturn(ID, TeamFlag: byte);
begin
mapdata[mflagreturns] := mapdata[mflagreturns] + 1;
if getplayerstat(ID,'human') then playerdata[ID][pflagreturns] := playerdata[ID][pflagreturns] + 1;
case teamflag of
	1: rfs := true;
	2: bfs := true;
	end;
end;

procedure OnFlagScore(ID, TeamFlag: byte);
begin
ascore := alphascore;
bscore := bravoscore;
mapdata[mflagcaps] := mapdata[mflagcaps] + 1;
if getplayerstat(ID,'human') then playerdata[ID][pflagcaps] := playerdata[ID][pflagcaps] + 1;
case teamflag of
	1: rfs := true;
	2: bfs := true;
	end;
end;

procedure OnPlayerKill(Killer, Victim: byte;Weapon: string);
var i,temp: byte; alive: array[0..5] of byte; count: boolean;
begin
for i := 1 to 32 do if getplayerstat(i,'active') then if getplayerstat(i,'alive') then begin
	temp := getplayerstat(i,'team');
	alive[temp] := alive[temp] + 1;
	end;
if survival then begin
	count := false;
	temp := getplayerstat(killer,'team');
	if temp = 1 then if alive[2] > 0 then count := true;
	if temp = 2 then if alive[1] > 0 then count := true;
	end else count := true;
if count then begin
	mapdata[mdeaths] := mapdata[mdeaths] + 1;
	playerdata[victim][pdeaths] := playerdata[victim][pdeaths] + 1;
	end;
if killer <> victim then begin
	mapdata[mkills] := mapdata[mkills] + 1;
	playerdata[killer][pkills] := playerdata[killer][pkills] + 1;
	end else if count then begin
		mapdata[mselfkills] := mapdata[mselfkills] + 1;
		playerdata[killer][pselfkills] := playerdata[killer][pselfkills] + 1;
		end;
end;