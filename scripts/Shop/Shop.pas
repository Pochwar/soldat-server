////////////////////////////
// Shop                 ///
// by dominikk26       ///
// Version 3.1        ///
////////////////////////

const
red = $FF0000;
green = $00DC00;
violet = $FF9F17F0;
activeWeapon = false;
activeBasic = false;
activeEquip = true;

type
Gracz=record
Ppass:string;
Pname:string;
Plogged:boolean;
Pkasa:integer;
end;

var
Player: array[0..32] of Gracz;
kasazazabicie:integer; // ile czegoś za coś
killTheFlagger:integer;
killAsFlagger:integer;
captureTheFlag:integer;
totalReward:integer;
resume:string;
med,nady,vest,clust,berserk,predator,flamegod,Desert,HK,AK,Steyr,Spas,Ruger,M79,Barrett,Minimi,Minigun,USSO,Knife,SAW,LAW,xp:integer; // cena przedmiotów

//========================================================================================================================================================================
function xsplit(const source: string; const delimiter: string):TStringArray;
var
	i,x,d:integer;
	s:string;
begin
	d:=length(delimiter);
	x:=0;
	i:=1;
	SetArrayLength(Result,1);
	while(i<=length(source)) do begin
		s:=Copy(source,i,d);   	
	    	if(s=delimiter) then begin
	    		inc(i,d);		
	    		inc(x,1);
	    		SetArrayLength(result,x+1);
	    	end else begin  	     
	    		result[x]:= result[x]+Copy(s,1,1);
	    		inc(i,1);
	  	end;
	end;
end;

type TSection = record
	Name: string;
	Keys: array of string;
end;

type TINIFile = record
	Sections: array of TSection;
end;

function iniLoad(FileName: string): TINIFile;
var
	iSections, iKeys, i: integer;
	lines: TStringArray;
begin
	lines := xsplit(ReadFile(FileName), chr(13) + chr(10));

	iSections := 0;
	iKeys := 0;

	for i := 0 to GetArrayLength(lines) - 1 do
	begin
		if Length(lines[i]) > 0 then
		begin
			if (lines[i][1] = '[') and (lines[i][Length(lines[i])] = ']') then
			begin
				iSections := iSections + 1;
				iKeys := 0;
				SetArraylength(Result.Sections, iSections);
				Result.Sections[iSections - 1].Name := Copy(lines[i], 2, Length(lines[i]) - 2);
			end
			else if (iSections > 0) and (StrPos('=', lines[i]) > 0) then
			begin
				iKeys := iKeys + 1;
				SetArrayLength(Result.Sections[iSections - 1].Keys, iKeys);
				Result.Sections[iSections - 1].Keys[iKeys - 1] := lines[i];
			end;
		end;
	end;
end;

procedure iniSave(FileName: string; var iniFile: TINIFile);
var
	i, j: integer;
	data: string;
begin
	for i := 0 to GetArrayLength(iniFile.Sections) - 1 do
	begin
		if Length(iniFile.Sections[i].Name) > 0 then
		begin
			data := data + '[' + iniFile.Sections[i].Name + ']' + chr(13) + chr(10);

			for j := 0 to GetArrayLength(iniFile.Sections[i].Keys) - 1 do
				if Length(iniFile.Sections[i].Keys[j]) > 0 then
					data := data + iniFile.Sections[i].Keys[j] + chr(13) + chr(10);

			if i < GetArrayLength(iniFile.Sections) - 1 then
				data := data + chr(13) + chr(10);
		end;
	end;

	WriteFile(FileName, data);
end;

function iniGetValue(var iniFile: TINIFile; section, key, errorResult: string): string;
var
	i, j, idx: integer;
begin
	Result := errorResult;

	if StrPos('=', key) > 0 then
	begin
		WriteLn('Error: the key can''t contain the character ''='' (asshole)');
		exit;
	end;

	for i := 0 to GetArrayLength(iniFile.Sections) - 1 do
	begin
		if LowerCase(iniFile.Sections[i].Name) = LowerCase(section) then
		begin
			for j := 0 to GetArrayLength(iniFile.Sections[i].Keys) - 1 do
			begin
				if GetPiece(iniFile.Sections[i].Keys[j], '=', 0) = key then
				begin
					idx := StrPos('=', iniFile.Sections[i].Keys[j]);
					Result := Copy(iniFile.Sections[i].Keys[j], idx + 1, Length(iniFile.Sections[i].Keys[j]));
					break;
				end;
			end;
			break;
		end;
	end;
end;

procedure iniSetValue(var iniFile: TINIFile; section, key, value: string);
var
	i, j: integer;
	sectionFound, keyFound: boolean;
begin
	if StrPos('=', key) > 0 then
	begin
		WriteLn('Error: the key can''t contain the character ''='' (asshole)');
		exit;
	end;

	sectionFound := false;
	keyFound := false;

	for i := 0 to GetArrayLength(iniFile.Sections) - 1 do
	begin
		if LowerCase(iniFile.Sections[i].Name) = LowerCase(section) then
		begin
			sectionFound := true;

			for j := 0 to GetArrayLength(iniFile.Sections[i].Keys) - 1 do
			begin
				if GetPiece(iniFile.Sections[i].Keys[j], '=', 0) = key then
				begin
					keyFound := true;
					iniFile.Sections[i].Keys[j] := key + '=' + value;
					break;
				end;
			end;

			if keyFound = false then
			begin
				j := GetArrayLength(iniFile.Sections[i].Keys);
				SetArrayLength(iniFile.Sections[i].Keys, j + 1);
				iniFile.Sections[i].Keys[j] := key + '=' + value;
			end;

			break;
		end;
	end;

	if sectionFound = false then
	begin
		i := GetArrayLength(iniFile.Sections);
		SetArrayLength(iniFile.Sections, i + 1);
		iniFile.Sections[i].Name := section;

		SetArrayLength(iniFile.Sections[i].Keys, 1);
		iniFile.Sections[i].Keys[0] := key + '=' + value;
	end;
end;

procedure iniDeleteSection(var iniFile: TINIFile; section: string);
var
	i: integer;
begin
	for i := 0 to GetArrayLength(iniFile.Sections) - 1 do
	begin
		if LowerCase(iniFile.Sections[i].Name) = LowerCase(section) then
		begin
			iniFile.Sections[i].Name := '';
			break;
		end;
	end;
end;

procedure iniDeleteKey(var iniFile: TINIFile; section, key: string);
var
	i, j: integer;
begin
	if StrPos('=', key) > 0 then
	begin
		WriteLn('Error: the key can''t contain the character ''='' (asshole)');
		exit;
	end;

	for i := 0 to GetArrayLength(iniFile.Sections) - 1 do
	begin
		if LowerCase(iniFile.Sections[i].Name) = LowerCase(section) then
		begin
			for j := 0 to GetArrayLength(iniFile.Sections[i].Keys) - 1 do
			begin
				if GetPiece(iniFile.Sections[i].Keys[j], '=', 0) = key then
				begin
					iniFile.Sections[i].Keys[j] := '';
					break;
				end;
			end;
			break;
		end;
	end;
end;

procedure iniWrite(FileName, section, key, value: string);
var
	iniFile: TINIFile;
begin
	iniFile := iniLoad(FileName);
	iniSetValue(iniFile, section, key, value);
	iniSave(FileName, iniFile);
end;
//========================================================================================================================================================================

procedure Komendy(ID:byte);
var komendyInfo: string;
begin
komendyInfo := '';  // Toujours initialiser la chaîne
  if activeWeapon then
    komendyInfo := komendyInfo + '!wep : buy weapons ';
  if activeBasic then
    komendyInfo := komendyInfo + '!basic : buy the basic weapons ';
  if activeEquip then
    komendyInfo := komendyInfo + '!kit : buy equipment ';
WriteConsole(ID,'____________________________________________________________________________',violet);
WriteConsole(ID, komendyInfo,violet);
WriteConsole(ID,'!money : display bank amount',violet);
WriteConsole(ID,'!accounts : information on accounts',violet);
WriteConsole(ID,'___________________________________________________________________________|',violet);
end;

procedure Ekwipunek(ID:Byte);
begin
if activeEquip then begin
WriteConsole(ID, '_____Equipment___________________',violet);
WriteConsole(ID, '/buy 1  - Grenades         $'+IntToStr(nady)+ '  |',violet);
WriteConsole(ID, '/buy 2  - Health           $'+IntToStr(med)+  '  |',violet);
WriteConsole(ID, '/buy 3  - Cluster Grenades $'+IntToStr(clust)+'  |',violet);
WriteConsole(ID, '/buy 4  - Vest             $'+IntToStr(vest)+ '  |',violet);
WriteConsole(ID, '/buy 5  - Berserk          $'+IntToStr(berserk)+ ' |',violet);
WriteConsole(ID, '/buy 6  - Predator         $'+IntToStr(predator)+ ' |',violet);
WriteConsole(ID, '/buy 7  - Flame God        $'+IntToStr(flamegod)+ ' |',violet);
WriteConsole(ID, '_________________________________|',violet);
end;
end;

procedure Bronie(ID:Byte);
begin
if activeWeapon then begin
WriteConsole(ID, '_____To buy weapons___________________',violet);
WriteConsole(ID, '/buy eagles  - Desert Eagles $'+IntToStr(Desert)+ '    |',violet);
WriteConsole(ID, '/buy HK MP5  - HK MP5        $'+IntToStr(HK)+     '    |',violet);
WriteConsole(ID, '/buy AK-74   - AK-74         $' +IntToStr(AK)+    '    |',violet);
WriteConsole(ID, '/buy AUG     - Steyr AUG     $'+IntToStr(Steyr)+  '    |',violet);
WriteConsole(ID, '/buy spas-12 - Spas-12       $'+IntToStr(Spas)+   '    |',violet);
WriteConsole(ID, '/buy ruger   - Ruger 77      $'+IntToStr(Ruger)+  '    |',violet);
WriteConsole(ID, '/buy M79     - M79           $'+IntToStr(M79)+    '    |',violet);
WriteConsole(ID, '/buy barret  - Barrett M82A1 $'+IntToStr(Barrett)+'    |',violet);
WriteConsole(ID, '/buy minimi  - FN Minimi     $'+IntToStr(Minimi)+ '    |',violet);
WriteConsole(ID, '/buy minigun - XM214 Minigun $'+IntToStr(Minigun)+'    |',violet);
WriteConsole(ID, '_____________________________________|',violet);
end;
end;

procedure Podstawowe(ID:Byte);
begin
if activeBasic then begin
WriteConsole(ID, '_____Basic Weapons___________________',violet);
WriteConsole(ID, '/buy USSOCOM   - USSOCOM      $'+IntToStr(USSO)+ '   |',violet);
WriteConsole(ID, '/buy knife     - Combat knife $'+IntToStr(Knife)+ '  |',violet);
WriteConsole(ID, '/buy SAW       - Chainsaw     $'+IntToStr(SAW)+  '   |',violet);
WriteConsole(ID, '/buy LAW       - M72 LAW      $'+IntToStr(LAW)+   '  |',violet);
WriteConsole(ID, '____________________________________|',violet);
end;
end;

procedure Accounts(ID:Byte);
begin
WriteConsole(ID, '_____Information on accounts________________',violet);
WriteConsole(ID,'/create <name> <pass> - create new account |',violet);
WriteConsole(ID,'/login <name> <pass> - login               |',violet);
WriteConsole(ID,'/logout - logout of Your account           |',violet);
WriteConsole(ID,'/save - save account                       |',violet);
WriteConsole(ID,'/reset - reset account                     |',violet);
WriteConsole(ID,'___________________________________________|',violet);
end;

procedure Money(ID:Byte);
begin
WriteConsole(ID, 'Money: '+IntToStr(Player[ID].Pkasa)+'$',red);
end;

//========================================================================================================================================================================
var konta: array[1..32] of TINIFile;

procedure Create(ID: byte; name, pass: string);
begin
if (FileExists('scripts/' +ScriptName+ '/konta/' + name + '.ini')) then WriteConsole(ID,'That name already exists! Please choose a different one.',red);
if not (FileExists('scripts/' +ScriptName+ '/konta/' + name + '.ini')) then begin
WriteFile('scripts/' +ScriptName+ '/konta/' + name + '.ini','');
konta[ID] := iniLoad('scripts/' +ScriptName+ '/konta/' + name + '.ini');
inisetvalue(konta[ID],'gracz','pass',pass);
inisetvalue(konta[ID],'gracz','kasa',inttostr(Player[ID].Pkasa));
iniSave('scripts/' +ScriptName+ '/konta/' + name + '.ini',konta[ID]);
WriteConsole(ID,'Account successfully created! Name-' + name + ' Password-' + pass,red);
end;
end;

procedure Login(ID: byte; name, pass: string);
var temp: TINIfile;
begin
if (FileExists('scripts/' +ScriptName+ '/konta/' + name + '.ini')) then begin
temp := iniload('scripts/' +ScriptName+ '/konta/' + name + '.ini');
if inigetvalue(temp,'gracz','pass','NO PASSWORD') = pass then begin
konta[ID] := iniLoad('scripts/' +ScriptName+ '/konta/' + name + '.ini');
Player[ID].Plogged := true;
Player[ID].Ppass := inigetvalue(konta[ID],'gracz','pass','0');
Player[ID].Pname := name;
Player[ID].Pkasa:=strtoint(inigetvalue(konta[ID],'gracz','kasa','1'));
WriteConsole(ID,'You have successfully logged in! Name-' + name + ' Password-' + pass,red);
exit;
end;
WriteConsole(ID,'Password incorrect!',red);
exit;
end;
WriteConsole(ID,'Account does not exitst! Please create one with /create NAME PASS',red);
exit;
end;

procedure Save(ID: byte; name, pass: string);
begin
if inigetvalue(konta[ID],'gracz','pass','NO PASSWORD') = pass then begin
inisetvalue(konta[ID],'gracz','kasa',inttostr(Player[ID].Pkasa));
iniSave('scripts/' +ScriptName+ '/konta/' + name + '.ini',konta[ID]);
WriteConsole(ID,'Account info successfully saved! Name-' + name,red);
end;
end;

procedure Logout(ID: byte);
begin
Player[ID].Ppass :='brak';
Player[ID].Pname:='brak';
Player[ID].Plogged:=false;
Player[ID].Pkasa:=0;
end;

procedure ResetStats(ID: Byte);
begin
Player[ID].Ppass :=Player[ID].Ppass;
Player[ID].Pname:=Player[ID].Pname;
Player[ID].Plogged:=Player[ID].Plogged;
Player[ID].Pkasa:=0;
end;
//========================================================================================================================================================================
procedure ActivateServer();
begin
kasazazabicie:=45;
killAsFlagger:=20;
killTheFlagger:=10;
captureTheFlag:=100;
////////// Sklep i Skille ///////////////
med		 :=235;
nady	 :=250;
vest   	 :=315;
clust	 :=335;
flamegod :=3000;
predator :=1500;
berserk	 :=1000;
Desert   :=269;
HK       :=290;
AK		 :=310;
Steyr	 :=245;
Spas	 :=195;
Ruger	 :=260;
M79		 :=315;
Barrett	 :=400;
Minimi   :=345;
Minigun  :=340;
USSO	 :=65;
Knife    :=100;
SAW		 :=70;
LAW      :=125;
////////// Sklep i Skille ///////////////

end;

// Test detect headshot
//function OnPlayerDamage(Victim,Shooter: Byte;Damage: Integer): integer;
//begin
//WriteConsole(Victim, 'test Victim',red);
//WriteConsole(Shooter, 'test shooter',red);
//WriteConsole(0, 'test',green);
//Result:=Damage;
//end;

procedure OnPlayerKill(Killer, Victim: byte;Weapon: string);
begin
  if GetPlayerStat(Killer, 'Team') <> GetPlayerStat(Victim, 'Team') then begin
    if (GetPlayerStat(Killer,'Human') = true) and (Killer<>Victim) then begin
      totalReward := kasazazabicie;
      resume :=  '+'+IntToStr(kasazazabicie)+'$ (Kill)'
      if GetPlayerStat(Victim, 'Flagger') = True then begin
        totalReward := totalReward + killTheFlagger;
        resume := resume + ' +'+IntToStr(killTheFlagger)+'$ (Kill the flagger)'
      end;
      if GetPlayerStat(Killer, 'Flagger') = True then begin
        totalReward := totalReward + killAsFlagger;
        resume := resume + ' +'+IntToStr(killAsFlagger)+'$ (Kill as flagger)'
      end;
      Player[Killer].Pkasa :=Player[Killer].Pkasa + totalReward;
      resume := resume + ' (Total: '+IntToStr(Player[Killer].Pkasa)+'$)'
      WriteConsole(Killer, resume, green);
    end;
  end;
  if GetPlayerStat(Killer, 'Team') = GetPlayerStat(Victim, 'Team') then begin
    if (GetPlayerStat(Killer,'Human') = true) and (Killer<>Victim) then begin
      if (Player[Killer].Pkasa - kasazazabicie >= 0) then begin
        Player[Killer].Pkasa	:=Player[Killer].Pkasa	-kasazazabicie;
      end else begin
        Player[Killer].Pkasa	:=0;
      end;
      WriteConsole(Killer, '-'+IntToStr(kasazazabicie)+'$ (total: '+IntToStr(Player[Killer].Pkasa)+'$)',red);
    end;
  end;
end;

procedure OnFlagScore(ID, TeamFlag: byte);
var t: byte;
var count: integer;
begin
  count := 0;
  for t:= 1 to 32 do begin
    if getplayerstat(t,'active') then begin
      count := count + 1;
    end;
  end;
  // Prevent farming being alone in server
  if (count > 1) then begin
    Player[ID].Pkasa	:=Player[ID].Pkasa	+ captureTheFlag;
    WriteConsole(ID, '+'+IntToStr(captureTheFlag)+'$ for capturing flag (total: '+IntToStr(Player[ID].Pkasa)+'$)',green);
  end;
end;

//========================================================================================================================================================================
function OnPlayerCommand(ID: Byte; Text: string): boolean;
begin
if getpiece(text,' ',0) = '/create' then
if getpiece(text,' ',2) <> nil then begin
	if Player[ID].Plogged then begin
	Save(ID,Player[ID].Pname,Player[ID].Ppass);
	Logout(ID);
	end;
Create(ID,getpiece(text,' ',1),getpiece(text,' ',2));
Login(ID,getpiece(text,' ',1),getpiece(text,' ',2));
end;

if getpiece(text,' ',0) = '/login' then
if getpiece(text,' ',2) <> nil then begin
	if Player[ID].Plogged then begin
	Save(ID,Player[ID].Pname,Player[ID].Ppass);
	Logout(ID);
	end;
Login(ID,getpiece(text,' ',1),getpiece(text,' ',2));
end;

if getpiece(text,' ',0) = '/logout' then begin
if Player[ID].Plogged then begin
Save(ID,Player[ID].Pname,Player[ID].Ppass);
Logout(ID);
WriteConsole(ID,'You have successfully logged out!',red);
exit;
end;
WriteConsole(ID,'You are not logged in, you cannot log out!',red);
end;

if Text='/reset' then ResetStats(ID);

if Text = '/save' then if Player[ID].Plogged then Save(ID,Player[ID].Pname,Player[ID].Ppass);
////////////////////////////////////////////////////////////////// Sklep i SkilleSkille ////////////////////////////////////////////////
if regExpMatch('^/(buy1|buy-1|buy 1|buy nade|buy nades|buy granades|buy nadepack)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then begin
      if Player[ID].Pkasa >= nady then begin
          Player[ID].Pkasa := Player[ID].Pkasa - nady;
          GiveBonus(ID,4);
          WriteConsole(ID, 'Grenades buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
      end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(nady)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy-2|buy2|buy 2|buy med|buy medkit|buy apteczka)$', lowercase(Text)) then
begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then
  begin
    if Player[ID].Pkasa >= med then
    begin
      Player[ID].Pkasa := Player[ID].Pkasa - med;
      
      if ReadINI('soldat.ini', 'GAME', 'Realistic_Mode', '0') = '1' then
      begin
        DoDamage(ID, GetPlayerStat(ID, 'Health') - 65);
        WriteConsole(ID, 'Medkit buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)', green);
      end
      else
      begin
        DoDamage(ID, GetPlayerStat(ID, 'Health') - 150);
        WriteConsole(ID, 'Medkit buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)', green);
      end;
      
    end
    else
      WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(med)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)', red);
  end;
end;

if regExpMatch('^/(buy-3|buy3|buy 3|buy clust|buy cluster|buy cluster granades)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then begin
      if Player[ID].Pkasa >= clust then begin
          Player[ID].Pkasa := Player[ID].Pkasa - clust;
          GiveBonus(ID,5);
          WriteConsole(ID, 'Cluster grenades buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
      end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(clust)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy vest|buy4|buy-4|buy 4|buy kamizelka)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then begin
      if Player[ID].Pkasa >= vest then begin
          Player[ID].Pkasa := Player[ID].Pkasa - vest;
          GiveBonus(ID,3);
          WriteConsole(ID, 'Vest buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
      end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(vest)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy berserk|buy5|buy-5|buy 5)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then begin
      if Player[ID].Pkasa >= berserk then begin
          Player[ID].Pkasa := Player[ID].Pkasa - berserk;
          GiveBonus(ID,2);
          WriteConsole(ID, 'Berserk bonus buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
      end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(berserk)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy predator|buy6|buy-6|buy 6)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then begin
      if Player[ID].Pkasa >= predator then begin
          Player[ID].Pkasa := Player[ID].Pkasa - predator;
          GiveBonus(ID,1);
          WriteConsole(ID, 'Predator bonus buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
      end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(predator)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy flame|buy flamegod|buy 7|buy7)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeEquip then begin
      if Player[ID].Pkasa >= flamegod then begin
          Player[ID].Pkasa := Player[ID].Pkasa - flamegod;
          GiveBonus(ID,6);
          WriteConsole(ID, 'FlameGod bonus buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
      end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(flamegod)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy desert eagles|buy eagle|buy deagles|buy deserteagles|buy eagles|buy eagle)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Desert then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Desert;
		forceWeapon(ID,1,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Desert Eagles buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Desert)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy hkmp5|buy mp5|buy hk|buy hk mp5)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= HK then begin
		Player[ID].Pkasa := Player[ID].Pkasa - HK;
		forceWeapon(ID,2,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'HK Mp5 buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(HK)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy ak74|buy ak|buy ak-74|buy ak 74|buy ak - 74|buy ak -74|buy ak- 74)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= AK then begin
		Player[ID].Pkasa := Player[ID].Pkasa - AK;
		forceWeapon(ID,3,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'AK 74 buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(AK)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy steyr|buy aug|buy Steyr AUG)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Steyr then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Steyr;
		forceWeapon(ID,4,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Steyr Aug buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Steyr)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy spas 12|buy spas-12|buy Spas|buy Spas 12|buy spas12|buy spas)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Spas then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Spas;
		forceWeapon(ID,5,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Spas 12 buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Spas)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy ruger|buy ruger77|buy Ruger|buy Ruger77|buy ruger 77|buy Ruger 77)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Ruger then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Ruger;
		forceWeapon(ID,6,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Ruger 77 buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Ruger)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy m79|buy M79|buy m-79|buy m 79| buy m- 79|buy m -79)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= M79 then begin
		Player[ID].Pkasa := Player[ID].Pkasa - M79;
		forceWeapon(ID,7,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'M79 buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(M79)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy barreta|buy Barreta|buy barr|buy Barr|buy BARR|buy barrett m82a1|buy Barrett M82A1|buy barret|buy Barret|buy baret|buy Baret|buy beret|buy Beret)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Barrett then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Barrett;
		forceWeapon(ID,8,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Barret M82a1 buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Barrett)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy fn minimi|buy FN|buy FN Minimi|buy minimi|buy Minimi|buy fn|buy M249 SAW|buy M249)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Minimi then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Minimi;
		forceWeapon(ID,9,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'FN Minimi buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Minimi)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy minigun|buy minig|buy Minigun|buy Minig|buy MiniG|buy Gun|buy gun)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeWeapon then begin
	if Player[ID].Pkasa >= Minigun then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Minigun;
		forceWeapon(ID,10,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Minigun buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Minigun)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy USSOCOM|buy ussocom|buy uscom|buy Uscom|buy usoco)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeBasic then begin
	if Player[ID].Pkasa >= USSO then begin
		Player[ID].Pkasa := Player[ID].Pkasa - USSO;
		forceWeapon(ID,0,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Ussocom buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(USSO)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy Combat Knife|buy combat knife|buy Combat knife|buy combat Knife|buy Combat|buy combat|buy Knife|buy knife)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeBasic then begin
	if Player[ID].Pkasa >= Knife then begin
		Player[ID].Pkasa := Player[ID].Pkasa - Knife;
		forceWeapon(ID,14,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Combat knife buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(Knife)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy SAW|buy Chainsaw|buy Chain|buy piła|buy bore|buy screw)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeBasic then begin
	if Player[ID].Pkasa >= SAW then begin
		Player[ID].Pkasa := Player[ID].Pkasa - SAW;
		forceWeapon(ID,15,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'Chainsaw buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(SAW)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;

if regExpMatch('^/(buy m72|buy law|buy M72 LAW)$',lowercase(Text)) then begin
  if (GetPlayerStat(ID,'Alive') = true) and activeBasic then begin
	if Player[ID].Pkasa >= LAW then begin
		Player[ID].Pkasa := Player[ID].Pkasa - LAW;
		forceWeapon(ID,16,GetPlayerStat(ID,'Primary'),0);
                WriteConsole(ID, 'M72 Law buyed! (money left: '+IntToStr(Player[ID].Pkasa)+'$)',green);
        end else  WriteConsole(ID, 'You do not have enough money! (Cost: '+IntToStr(LAW)+'$ - money left: '+IntToStr(Player[ID].Pkasa)+'$)',red);
  end;
end;
Result:=false;
end;
//========================================================================================================================================================================

procedure OnMapChange(NewMap: String);
var t: byte;
begin
for t:= 1 to 32 do begin
	if getplayerstat(t,'human') then begin
	if Player[t].Plogged then begin
		Save(t,Player[t].Pname,Player[t].Ppass);
		writeconsole(t,'All Accounts saved',red)
		end;
	end;
end;
end;

procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
//if (Text = '!cmd') or (Text = '!cmds') or (Text = '!help') or (Text = '!shop')then Komendy(ID);
if (Text = '!equip') or (Text = '!equipment') or (Text = '!outfit') or (Text = '!kit') then Ekwipunek(ID);
if (Text = '!weapons') or (Text = '!wep') or (Text = '!weap') then Bronie(ID);
if (Text = '!basic') then Podstawowe(ID);
if (Text = '!money') then Money(ID);
if (Text = '!accounts') or (Text = '!accou') or (Text = '!accout') or (Text = '!account') or (Text = '!acco') then Accounts(ID);
end;

procedure OnJoinGame(ID, Team: byte);
begin
if (GetPlayerStat(ID,'Human') = true) then begin
Player[ID].Ppass :='brak';
Player[ID].Pname:='brak';
Player[ID].Plogged:=false;
Player[ID].Pkasa:=320;
end;
end;

procedure OnLeaveGame(ID, Team: byte;Kicked: boolean);
begin
if (GetPlayerStat(ID,'Human') = true) and (Player[ID].Plogged=true) then begin
Save(ID,Player[ID].Pname,Player[ID].Ppass);
Player[ID].Pname := 'brak';
Player[ID].Ppass := 'brak';
Player[ID].Plogged := false;
end;
end;

function OnCommand(ID: Byte; Text: string): boolean;
var target: byte;
begin
if (Text = '/givemoney') then Player[ID].Pkasa := Player[ID].Pkasa + 500;
Result := false;
end;