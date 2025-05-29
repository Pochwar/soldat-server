procedure AppOnIdle(Ticks: integer);
var
  messages: array[0..3] of string;
  randomIndex: integer;
begin
  if Ticks mod(4800*2) = 0 then begin
   WriteConsole(0,'To discuss about functionnalities, maps and more',$EEe35d10);
   WriteConsole(0,'Join Discord server "Pochwar''s Soldat Servers" - https://discord.gg/r2qf9uUR',$EEe35d10);
  end;

  if Ticks mod(3600) = 0 then begin
    messages[0] := 'Tip: To save your money, create an account by typing "!accounts"';
    messages[1] := 'Tip: Use your money to buy bonuses! See available bonuses by typing "!kit"';
    messages[2] := 'Tip: Heal your teammates and get points as Medic by typing "!medic"';
	messages[3] := 'Tip: As medic, you can heal yourself by switching weapons';

    randomIndex := random(0, 4);

    WriteConsole(0, Messages[RandomIndex], $EEd6025e);
  end;
end;