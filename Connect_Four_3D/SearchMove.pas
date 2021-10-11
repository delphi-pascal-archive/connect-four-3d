{ **************************************************************************** }
{ Project: ConnectFour3D
{ Module:  
{ Author:  Josef Schuetzenberger
{ E-Mail:  schutzenberger@hotmail.com
{ WWW:     http://members.fortunecity.com/schutzenberger/download/en.html#ConnectFour3D
{ This unit is based on work by J.T. Deuter
{ **************************************************************************** }
{ Copyright ©2006 Josef Schuetzenberger
{ This programme is free software; you can redistribute it and/or modify it
{ under the terms of the GNU General Public License as published by the Free
{ Software Foundation; either version 2 of the License, or any later version.
{
{ This programme is distributed for educational purposes in the hope that it
{ will be useful, but WITHOUT ANY WARRANTY. See the GNU General Public License
{ for more details at http://www.gnu.org/licenses/gpl.html
{ **************************************************************************** }
unit SearchMove;

interface
uses SearchThread,SearchUtil,SearchMove2,TransTable;
type TWLine=array of int64;
     TWLines=array [0..N_SQR-1] of TWLine;
     TWLine1=array[0..69] of cardinal;

var  WLinesP1:TWLines;
     WLinesP2:TWLines;
     WLines1:TWLine1;

     StrategicScore:Boolean;
     BackMoves:integer;
     LastMove:integer;
     LastMoveList:array[0..43] of integer;
procedure  FindBestMove(aCrntLvl:integer;Player1Board,Player2Board:int64;var Move,Score:integer);
function GetMoves3(var aMoveList: array of integer): integer;

implementation
////////////////////////////////////////////////////////////////////////////////
// Make shorter array with possible winning lines
//
var shift,shift2,WLHigh:integer;
procedure MakeShortWinLines1;
var j,n:integer;
begin
    n:=-1;shift:=999999;shift2:=999999;
    for j:=0 to N_WL-1 do
    begin
      if j=41 then shift:=n;
      if j=63 then shift2:=n;
      if  ((WIN_LINES1[j] and BtBrd[1]) = 0)
      or  ((WIN_LINES1[j] and BtBrd[2]) = 0) then
      begin
        inc(n);
        if j < 41 then begin
          WLines1[n]:=WIN_LINES1[j];
        end else
          if j < 63 then begin
           WLines1[n]:=WIN_LINES1[j] shr 8;
          end else begin
           WLines1[n]:=WIN_LINES1[j] shr 12;
          end;
      end;
    end;
    WLHigh:=n;
end;
////////////////////////////////////////////////////////////////////////////////
// Make array with possible Winlines assoziated to a Position on board for Player 1 and 2
//
procedure MakeShortWinLinesP12;
var i,j,n,n1:integer;Board:int64;
begin
  Board:=BtBrd[1] or BtBrd[2];
  for i:=0 to N_SQR-1 do
  begin
    n:=0;
    WLinesP1[i]:=nil;
    n1:=0;
    WLinesP2[i]:=nil;
    if ((Board and SET_MASK[i]) = 0) then
    for j:=0 to N_WL-1 do
    begin
      if  ((WIN_LINES[j] and SET_MASK[i]) > 0)
      then
      begin
        if ((WIN_LINES[j] and BtBrd[2])    = 0) then
        begin
          inc(n);
          SetLength(WLinesP1[i],n);
          WLinesP1[i][n-1]:=WIN_LINES[j];
        end;
        if ((WIN_LINES[j] and BtBrd[1])    = 0) then
        begin
          inc(n1);
          SetLength(WLinesP2[i],n1);
          WLinesP2[i][n1-1]:=WIN_LINES[j];
        end;
      end;
    end;
  end;
end;
////////////////////////////////////////////////////////////////////////////////
// Examine the current game board position as stored by the aPlayer bit board
// and go through all winning line combinations masking out all counters on bit
// board other than winning line to see if it is a winner
//{$O-}
function CheckPlayerWin2(const aPlayer,Ni: integer): Boolean;  register;
asm
    PUSH ESI
    PUSH EDI
    PUSH EBX
    MOV ESI,NI     //Load winning lines at last move position for current player
    MOV EDI,aPlayer
    CMP EDI,1      //Player 1 or 2
    JNE @@p
    MOV ESI,DWORD PTR [WLinesP1+ESI*4]
    JMP @@n
@@p:MOV ESI,DWORD PTR [WLinesP2+ESI*4]
@@n:TEST ESI,ESI
    JZ  @@s
    MOV EBX,[ESI-4]
    LEA EDI,[BtBrd+EDI*8]       // get board of current player
    DEC EBX
    MOV ECX,DWORD PTR [EDI+4]
    MOV EDI,DWORD PTR [EDI]
@@a:MOV EAX,DWORD PTR [ESI+EBX*8]
    MOV EDX,EDI
    AND EDX,EAX
    CMP EDX,EAX
    JNZ @@e
    MOV EDX,DWORD PTR [ESI+EBX*8+4]
    MOV EAX,ECX
    AND EAX,EDX
    CMP EDX,EAX
    JNZ  @@e
    MOV AL,1  //four in a row found
    JMP @@z
@@e:DEC EBX
    JNL @@a
@@s:MOV AL,0  //not four in a row
@@z:POP EBX
    POP EDI
    POP ESI
end;

////////////////////////////////////////////////////////////////////////////////
// Look at the current game board position as stored by the BtBrds and fill
// aMoveList with valid cell numbers. Return the number of valid moves
(*$WARNINGS OFF*)
function GetMoves3(var aMoveList: array of integer): integer;
var  nOcpd, nNxtMves: Int64;
begin
  // Calulate a BitBoard containing only valid moves
  nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  nNxtMves := nOcpd xor ((nOcpd shl 7) or FRST_ROW) and BRD_FULL;
      asm
           push    esi
           xor     ebx,ebx
           mov     esi,aMoveList
           mov     ecx,1     //for ecx:=1 to 7 do
  //    if (nOcpd and SET_MASK[N_SQR-i])>0 then continue;
    @@loop:mov     eax,N_SQR
           sub     eax,ecx
           cmp     eax,$20
           jnl     @@n1
           bt      dword ptr nOcpd,eax
           jc      @@cont    // full col hence continue
      @@n1:sub     eax,$20
           bt      dword ptr nOcpd+4,eax
           jc      @@cont    // full col hence continue
      //   nM := BitScanForward(nNxtMves);
           mov     edx, dword ptr nNxtMves
           and     edx, COL_06         // repress moves on the side of the board
           bsf     eax, edx
           jnz     @@2                 // jump if there is a move on the side
           mov     edx, dword ptr nNxtMves
           and     edx, MID_COL        // prefer move around the center of the board
           bsf     eax, edx
           jnz     @@2                 // jump if there is a move in the center
           mov     edx, dword ptr nNxtMves
           and     edx, CENT_COL       // prefer move in the center of the board
           bsf     eax, edx
           jnz     @@2                 // jump if there is a move in the center
           bsf     eax, dword ptr nNxtMves
           jnz     @@2                 // jump if there is a move
           bsf     eax, dword ptr nNxtMves+04h
           jz      @@cont              // jump if there is no move (that should never happen)
           btr     dword ptr nNxtMves+04h,eax  // remove move from nNxtMves
           add     eax, 20h
           jmp     @@e
      @@2: btr     dword ptr nNxtMves,eax   // remove move from nNxtMves
      //   aMoveList[ebx] := nM;
      @@e: mov     [esi+ebx*4],eax
           inc     ebx
    @@cont:inc     ecx
           cmp     ecx,8
           jnz     @@loop
           mov     eax,ebx   // Result := nI;
           pop     esi
    end;
end;
 ////////////////////////////////////////////////////////////////////////////////
// Evaluate the current game board position as stored by the BtBrds with respect
// to the aPlayer
function GetScore3(const aPlayer: integer): integer; register;
var
  a4,b4: Int64;
  a,b:cardinal;
begin
asm
 push esi
 push edi
 mov ebx,WLHigh
 xor esi,esi
 test ebx,ebx
 jl @@lend
 lea esi,BtBrd
 mov ecx,dword ptr [esi+eax*8]
 mov edx,dword ptr [esi+eax*8+4]
 mov integer(a4),ecx
 mov integer(a4+4),edx
 mov edi,3
 sub edi,eax
 mov eax,dword ptr [esi+edi*8]
 mov edx,dword ptr [esi+edi*8+4]
 mov integer(b4),eax
 mov integer(b4+4),edx
 // a4:=BtBrd[aPlayer];
 // b4:=BtBrd[3 - aPlayer];
 // nWl:=High(WLines1);
 // Go through all winning line combinations
 // nS := 0;
  mov eax,dword ptr a4
  mov edx,dword ptr a4+4
  lea  edi,[WLines1]
  shrd eax,edx,12
  mov a,eax
  mov eax,dword ptr b4
  mov edx,dword ptr b4+4
  mov ebx,WLHigh
  shrd eax,edx,12
  xor esi,esi
  mov b,eax
//  a:=a4 shr 12;
//  b:=b4 shr 12;
//  while nWL >= 0 do
//  begin
//     test ebx,ebx
//     jl @@lend
nop
nop
nop
@@loop:cmp bx,[shift2]
      jnz @@y1
      mov eax,dword ptr a4
      mov edx,dword ptr a4+04h
      shrd eax,edx,8
      mov a,eax
      mov edx,dword ptr b4+04h
      mov eax,dword ptr b4
      shrd eax,edx,8
      mov b,eax
@@y1: cmp bx,[shift]
      jnz @@y2
      mov eax,dword ptr a4
      mov edx,dword ptr b4
      mov a,eax
      mov b,edx
@@y2:
 {   if nWl=shift2 then begin
      a:=a4 shr 8;
      b:=b4 shr 8;
    end;
    if nWl=shift then
    begin
      a:=a4;
      b:=b4;
   end;
  }
    // Mask out all counters on bit board other than winning line

   // nWLaM := a and WLines1[nWL];
   // nWLbM := b and WLines1[nWL];
   // Look up Player B's number of counters in this winning line
   // If (nWLbM > 0) and (nWLaM = 0) then
   // begin
       mov  eax,[edi+ebx*4]
       mov  edx,eax
       and  edx, a
       and  eax, b
       jz   @@w0
       test edx,edx
       jnz  @@1w
  @@0: lea  ecx, [eax-1]
       inc  edx
       and  eax, ecx
       jnz  @@0
       DEC  ESI
       DEC  edx
       JZ   @@1w
       SUB  ESI,3
       DEC  edx
       JZ   @@1w
       SUB  ESI,5
       JMP  @@1w
   {  nC := BitCount3(nWLbM);
      case nC of
        1: Dec(nS);
        2: Dec(nS, 4);
        3: Dec(nS, 9);
      end;
    end  }
    // Look up Player A's number of counters in this winning line
    // If (nWLaM > 0) and (nWLbM = 0) then
    // begin
@@w0:  test edx, edx
       jz   @@1w
@@x0:  lea  ecx, [edx-1]
       inc  eax
       and  edx, ecx
       jnz  @@x0
       INC  ESI
       DEC  EAX
       jz   @@1w
       ADD  ESI,3
       DEC  EAX
       JZ   @@1w
       ADD  ESI,5
@@1w:
{     nC := BitCount3(nWLaM);
      case nC of
        1: Inc(nS);
        2: Inc(nS, 4);
        3: Inc(nS, 9);
      end;   }
    // Look at next winning line
    dec ebx
    jnl @@loop
@@lend:
    mov ebx, esi  // set result
    pop edi
    pop esi
    end;
//  dec(nWL);
//  end;
// Return final evaluation of position
//  Result := nS;

end;
(*$WARNINGS ON*)


///////////////////////////////////////////////////////////////////////////////
// Recursively search for the best move
function NegaMaxEval(aDepth, aPlayer, aAlpha, aBeta: integer{;Node:PNode}): integer;
var
  nI,i, nNM, nBV, nSV, nMxAB: integer;
  nMvLst: array [0..(N_COL - 1)] of integer;
begin
    // Set up variables and get move list
    nBV := -INFINITY;
    nMxAB := aAlpha;
    nNM := GetMoves3(nMvLst);
   // If a move in this ply wins the game, set result and take it.
    for i:=0 to nNM-1 do
    begin
      nI := nMvLst[i];
      DoMove(nI,aPlayer);
      if CheckPlayerWin2(aPlayer,nI) then
      begin
        // If this move wins the game, undo move and take it. Give more weight to
        // a win if it happens a ply sooner than going another level into the tree
        result := SCR_WIN - 42 + aDepth;
        UndoMove(nI,aPlayer);
        exit;
      end;
      UndoMove(nI,aPlayer);
    end;
    // Go through each possible move at this node
    while (nNM > 0) and (nBV < aBeta) do
    begin
      // Extract a move from the move list and play it
      Dec(nNM);
      nI := nMvLst[nNM];
      DoMove(nI,aPlayer);
        // Recursively search values of next moves or get score
        // Return the value of the position at this leaf if required depth reached or
        // the board is full
      if (aDepth <= 1) or ((BtBrd[PT_PLR1] or BtBrd[PT_PLR2]) = BRD_FULL) then
           nSV := -GetScore3(3 - aPlayer)
      else // otherwise find all of player's opponent's replies
           nSV := -NegaMaxEval(aDepth - 1, 3 - aPlayer, -aBeta, -nMxAB);
      UndoMove(nI,aPlayer);
      // If a better position is found update alpha-beta
      if nSV > nBV then
      begin
        nBV := nSV;
        if nBV > nMxAB then nMxAB := nBV;
      end;
    end;
    Result := nBV;
end;

function EvalFirstMoves(var aMoveList: TMoves;aPlayer,aDepth:integer): integer;
var
  nOcpd, nNxtMves: Int64;
  nI, nM,i,k,z,nSV,nBV: integer;
  tmpMvLst:TMoves;
begin
  nBV := -INFINITY;
  // Calulate a BitBoard containing only valid moves
  nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  nNxtMves := nOcpd xor ((nOcpd shl 7) or FRST_ROW) and BRD_FULL;
  Ni:=0;
  for i:=1 to 7 do
  begin
    if (nOcpd and SET_MASK[N_SQR-i])>0 then continue;
    nM := BitScanForward(nNxtMves);
    nNxtMves := nNxtMves and RESET_MASK[nM];
    BtBrd[aPlayer] := BtBrd[aPlayer] or SET_MASK[nm];
    MakeShortWinLines1;
    if CheckPlayerWin2(aPlayer,nm) then
    begin
      nSV := INFINITY;;
    end else
    begin
      nSV := -NegaMaxEval(aDepth - 1, 3 - aPlayer, -INFINITY, -nBV);
    end;
    BtBrd[aPlayer] := BtBrd[aPlayer] and RESET_MASK[nm];
    tmpMvLst[nI].Move:= nM;
    tmpMvLst[nI].nBV:= nSV;
    inc(Ni);
  end;
  for i:=Ni-1 downto 0  do
  begin
    nSV:=-INFINITY;z:=-1;
    for k:=0 to Ni-1 do
    begin
     if  tmpMvLst[k].nBV > nSV then
     begin
        nSV:=tmpMvLst[k].nBV;
        z:=k;
      end;
    end;
    aMoveList[i].Move := tmpMvLst[z].Move;
    aMoveList[i].nBV := tmpMvLst[z].nBV;
    tmpMvLst[z].nBV:= -19999;
  end;
  Result := nI;
end;
function EvalRandomMoves(var aMoveList: TMoves;aPlayer:integer): integer;
var Randomlist:array[0..6] of integer;
procedure MakeRandomList(Ni:integer);
var i,j,z:integer;
begin
  Randomize;
  Randomlist[0]:=trunc(Random(Ni));
  for i:=1 to Ni-1 do
  begin
    repeat
      z:=trunc(Random(Ni));
      for j:=0 to i-1 do  if z=Randomlist[j] then break;
    until j=i;
    Randomlist[i]:=z;
  end;
end;
var
  nOcpd, nNxtMves: Int64;
  nI, nM,i,k,z,nSV: integer;
  tmpMvLst:TMoves;
begin
  // Calulate a BitBoard containing only valid moves
  nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  nNxtMves := nOcpd xor ((nOcpd shl 7) or FRST_ROW) and BRD_FULL;
  Ni:=0;
  for i:=1 to 7 do
  begin
    nSV:=0;
    if (nOcpd and SET_MASK[N_SQR-i])>0 then continue;
    nM := BitScanForward(nNxtMves);
    nNxtMves := nNxtMves and RESET_MASK[nM];
    BtBrd[aPlayer] := BtBrd[aPlayer] or SET_MASK[nm];
    MakeShortWinLines1;
    BtBrd[3-aPlayer] := BtBrd[3-aPlayer] or SET_MASK[nm];
    if CheckPlayerWin2(3-aPlayer,nm) then
    begin
      nSV := INFINITY-1;
    end;
    BtBrd[3-aPlayer] := BtBrd[3-aPlayer] and RESET_MASK[nm];
    if CheckPlayerWin2(aPlayer,nm) then
    begin
      nSV := INFINITY;
    end;
    BtBrd[aPlayer] := BtBrd[aPlayer] and RESET_MASK[nm];
    tmpMvLst[nI].Move:= nM;
    tmpMvLst[nI].nBV:= nSV;
    inc(Ni);
  end;
  MakeRandomList(Ni);
  for i:=Ni-1 downto 0  do
  begin
    nSV:=-INFINITY;z:=-1;
    for k:=0 to Ni-1 do
    begin
     if  tmpMvLst[k].nBV > nSV then
     begin
        nSV:=tmpMvLst[k].nBV;
        z:=k;
      end;
    end;
    aMoveList[RandomList[i]].Move := tmpMvLst[z].Move;
    aMoveList[RandomList[i]].nBV := tmpMvLst[z].nBV;
    tmpMvLst[z].nBV:= -19999;
  end;
  Result := nI;
end;
function HashFindPNodeFromLastMove:PTransItem;
var aBtBrd:TBtBrd;Player2,Board:int64;
    i,j,k:integer;
begin
  aBtBrd:=BtBrd;
  Board := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  Player2:=BtBrd[PT_PLR2] and not (Board shr 7);
  j:=BitCount(Player2);
  for i:=1 to j do
  begin
    k:=BitScanForward(Player2);
    Player2 := Player2 and RESET_MASK[k];
    BtBrd[PT_PLR2] := BtBrd[PT_PLR2] and RESET_MASK[k];
    result:=HashFindPNode;
    BtBrd:=aBtBrd;
    if result<>nil then
    begin
      if result.Score<0 then
      begin
        BtBrd:=aBtBrd;
        exit;     //Player 2 lost anyway so exit
      end;
    end;
  end;
  result:=nil;
  BtBrd:=aBtBrd;
end;
function AllMovesHaveSameLoosingScore(MoveList:TMoves;nM:integer):boolean;
var nBV,i:integer;
begin
  result:=false;
  nBV:=MoveList[0].nBV;
  if nBV >= -500 then exit; //game not already lost
  for i:=0 to nM-1 do
  begin
    if MoveList[i].nBV <> nBV then exit; //different score found
  end;
  result:=true;
end;
////////////////////////////////////////////////////////////////////////////////
// Find the best move of all the root nodes
//function NegaMaxRoot(const aDepth, aPlayer: integer; out aBestMove,aScore: integer):integer;
procedure NegaMaxRoot(const aDepth, aPlayer: integer; out aBestMove,aScore: integer);
var
  Iter ,nI, nNM, nNM1, nBV, nSV, depth, alpha: integer;
  nMvLst: TMoves;
  P:PTransItem;
begin
  MakeShortWinLinesP12;
  nNM1 := EvalRandomMoves(nMvLst,aPlayer);
  aScore := -INFINITY;
  aBestMove:=-1;
  for nI:=0 to nNM1-1 do
  begin
    if nMvLst[nI].nBV >= aScore then
    begin
      aScore:=nMvLst[nI].nBV;
      aBestMove:=nMvLst[nI].Move;
    end;
  end;
  if (aScore=INFINITY) or (aDepth=1) then
  begin
    if aScore < INFINITY then aScore:=0;  //move prevents 4 in a row
    if aScore = INFINITY then aScore:=10; //move creates 4 in a row
    exit;
  end;
  if aDepth<9 then Depth:=aDepth else Depth:=9;
  nNM1 := EvalFirstMoves(nMvLst,aPlayer,Depth);
  aScore := -INFINITY;
  if AllMovesHaveSameLoosingScore(nMvLst,nNM1) then exit; //take best move from EvalRandomMoves
  for nI:=0 to nNM1-1 do
  begin
    if nMvLst[nI].nBV > aScore then
    begin
      aScore:=nMvLst[nI].nBV;
      aBestMove:=nMvLst[nI].Move;
    end;
  end;
  assert(aBestMove>-1,'abestmove=-1');
  if (abs(aScore)>600) or (aDepth<=9) then
  begin
    if abs(aScore) <  600 then aScore:= 0; // draw
    if aScore      < -600 then aScore:=-5; // lost
    if aScore      >  600 then aScore:= 5; // won
    exit;
  end;
  MakeShortWinLinesP12;
  MakeShortWinLinesP;
  HashClearn;
  // Set up variables and get move list
  Depth:=aDepth;
  for  Iter:=0 to 2 do
  begin
    if Iter=0 then
    begin
      if Depth<13 then continue;
      Depth:=aDepth div 2;
      CrntLvl:=Depth;
    end;
    if Iter=1 then
    begin
      if Depth<13 then continue;
      Depth:=aDepth div 2;
      Depth:=Depth +Depth div 2;
      CrntLvl:=Depth;
    end;
    if Iter=2 then
    begin
      CrntLvl:=aDepth;
      Depth:=aDepth;
    end;
    if Depth=-1 then break;
    HashCompress;
    nBV := -INFINITY;
    alpha:=-1;
    nNM:=BitCount(BtBrd[PT_PLR1] or BtBrd[PT_PLR2]);
  //  if nNM < 11 then HashLoad9;
  //  if nNM < 11 then LoadBook('Book.dat');
    if nNM < 11 then LoadBookFromResource('Book.dat');

    if nNM = 9 then
    begin
      p:=HashFindPNode;
      if p<>nil then
      begin
        if p.Score>0 then
          nBV := 0;       //Player 2 won, just find the winning move
        if p.Score=0 then
          alpha := 0;     //Draw, there is no winning move to find
        if p.Score<0 then
          begin
            aScore:=-1;   //Player 2 lost anyway so exit
            exit;
          end;
      end;
    end;
    if nNM = 10 then
    begin
      p:=HashFindPNodeFromLastMove;
      if p<>nil then
      begin
        if p.Score<0 then
        begin
          nBV := 0; //Player 1 won, just find the winning move
        end;
      end;
    end;
    nNM := nNM1;
    LastNode:=0;
    aBestMove := -1;
    while (nNM > 0)  and (nBV < 600) do
    begin
      // Extract a move from the move list and play it
      Dec(nNM);
      nI := nMvLst[nNM].Move;
      if nMvLst[nNM].nBV<-500 then  //If this move loses the game
      begin
         if aBestMove<0 then  // and so far no move and score stored
         begin
           aBestMove:=nI;
           aScore:=nMvLst[nNM].nBV;
         end;
         continue; // this move loses the game, try the next move
      end;
      BtBrd[aPlayer] := BtBrd[aPlayer] or SET_MASK[nI];
      MakeShortWinLines1;
      // If this move wins the game, undo move and take it !!!
      if CheckPlayerWin2(aPlayer,nI) then
      begin
        aBestMove := nI;
        aScore:=500;
        nBV:=500;
        BtBrd[aPlayer] := BtBrd[aPlayer] and RESET_MASK[nI];
        Break;
      end
      // Otherwise find all of player's opponent's replies
      else
      begin
        MakeShortWinLinesP;
        WLinesP1B:=WLinesP1n;
        WLinesP2B:=WLinesP2n;
        LastMove:=nI;
        LastMoveList[Depth]:=nI;
        BackMoves:=-1;
        StrategicScore:=false;
        nSV := -NegaMaxAB3test(Depth - 1, 3 - aPlayer, alpha, -Sign(nBV));
        BtBrd[aPlayer] := BtBrd[aPlayer] and RESET_MASK[nI];
        // If the sucessor's position is found to be better, update the best move
        if nSV > nBV then
        begin
          nBV := nSV;
          aScore:=nBV;
          aBestMove := nI;
          if aScore>0 then
          begin
            aScore:=aScore+2-Iter;
            exit;  //If this move wins the game, stop searching and take it !!!
          end;
        end;
        if CancelSearch then
        begin
          if aBestMove=-1 then aBestMove:=nI;
          exit;   //Search canceled by the user
        end;
      end;
    end;  //try next move
    if nBV<0 then
    begin
      aScore:=nBV-(2-Iter);
      break;   //Break because the game is lost anyway.
    end;
  end; //for Iter
end;

function IsBoardValid:boolean;
var j:integer;
begin
  result:=false;
  for j:=0 to N_WL-1 do
      if  ((WIN_LINES[j] and BtBrd[1]) = WIN_LINES[j])
      or  ((WIN_LINES[j] and BtBrd[2]) = WIN_LINES[j]) then exit;
  result:=true;
end;
procedure  FindBestMove(aCrntLvl:integer;Player1Board,Player2Board:int64;var Move,Score:integer);
var Player:integer;
begin
  CrntLvl:=42-BitCount(Player1Board or Player2Board);
  if CrntLvl > aCrntLvl then CrntLvl:=aCrntLvl;
  BtBrd[PT_PLR1]:=Player1Board;
  BtBrd[PT_PLR2]:=Player2Board;
  Player:=1+BitCount(BtBrd[PT_PLR1] or BtBrd[PT_PLR2]) mod 2;
  if IsBoardValid then
   NegaMaxRoot(CrntLvl, Player, Move, Score)
  else
   Move:=-2;
end;
end.
