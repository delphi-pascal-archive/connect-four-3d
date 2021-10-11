{ **************************************************************************** }
{ Project: ConnectFour3D
{ Module:  
{ Author:  Josef Schuetzenberger
{ E-Mail:  schutzenberger@hotmail.com
{ WWW:     http://members.fortunecity.com/schutzenberger/download/en.html#ConnectFour3D
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
unit SearchMove2;
                                                                  
interface
uses SearchThread,SearchUtil;
type TWLinen=array[0..15] of int64;
     TWLinesn=array [0..N_SQR-1] of TWLinen;
var
  WLinesP1n:TWLinesn;
  WLinesP2n:TWLinesn;
  WLinesP1B:TWLinesn;
  WLinesP2B:TWLinesn;
  CrntLvl:integer;

procedure MakeShortWinLinesP;
function NegaMaxAB3test(aDepth, aPlayer, aAlpha, aBeta: integer): integer;

implementation
uses SearchMove,TransTable;


////////////////////////////////////////////////////////////////////////////////
// Make array with possible Winlines assoziated to a Position on board for Player 1 an 2
//
procedure MakeShortWinLinesP;
var i,j,k,n,n1:integer;
begin
  for i:=0 to N_SQR-1 do
  begin
    n:=0;n1:=0;
    if WLinesP1[i]<>nil then
    begin
      k:=high(WLinesP1[i]);
      for j:=0 to k do
      begin
          if ((WLinesP1[i][j] and BtBrd[2]) = 0) then
          begin
            inc(n);
            WLinesP1n[i][n]:=WLinesP1[i][j];
          end;
      end;
    end;
    WLinesP1n[i][0]:=n;
    if WLinesP2[i]<>nil then
    begin
      k:=high(WLinesP2[i]);
      for j:=0 to k do
      begin
          if ((WLinesP2[i][j] and BtBrd[1]) = 0) then
          begin
            inc(n1);
            WLinesP2n[i][n1]:=WLinesP2[i][j];
          end;
      end;
    end;
    WLinesP2n[i][0]:=n1;
  end;
end;
////////////////////////////////////////////////////////////////////////////////
// Do a move and examine the current game board position as stored by the aPlayer bit board
// and go through all winning line combinations masking out all counters on bit
// board other than winning line to see if it is a winner
function CheckMoveForWin(const aPlayer,Ni: integer): Boolean;  register;
asm
    PUSH ESI
    PUSH EDI
    PUSH EBX
    MOV EDI,aPlayer
    MOV EAX,Ni     //Load winning lines at last move position for current player
    CMP EDI,1      //Player 1 or 2
    JNE @@p
    MOV ESI,DWORD PTR [WLinesP1+EAX*4]
    JMP @@n
@@p:MOV ESI,DWORD PTR [WLinesP2+EAX*4]
@@n:TEST ESI,ESI
    JZ  @@s
    MOV EBX,[ESI-4]
    LEA EDI,[BtBrd+EDI*8]       // get board of current player
    DEC EBX
    MOV ECX,DWORD PTR [EDI+4]
    MOV EDI,DWORD PTR [EDI]

    cmp eax,$20
    jnl @@k
    bts edi,eax    // set counter on low word
    jmp @@a
@@k:sub eax,$20
    bts ecx,eax    // set counter on high word

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
{var  nWL,i: integer;
begin
  nWL := 0;
  i:=High(WLines[Ni]);
  while nWL <= i do
  begin
    if WLines[Ni,nWL] = ((BtBrd[aPlayer] and WLines[Ni,nWL])) then
    begin
      Result := True;
      Exit
    end;
    Inc(nWL);
  end;
  Result := False;
 }

function AreGroupsinBoardBP1(const Groups,Board:int64): boolean;
var  nI, nM,i: integer;nNxtMves:int64;
begin
  nNxtMves:=Groups;
  result:=true;
  repeat      //look whether moves in nNxtMves have a winning line in Player1Brd
    nM := BitScanForward(nNxtMves);
    if nM<0 then break;
    nI:=WLinesP1n[nM][0];
    for i:=1 to nI do
    begin
      if (WLinesP1n[nM][i] and Board )=0 then exit;
    end;
    nNxtMves := nNxtMves and RESET_MASK[nM];
  until false;
  result:=false;
end;
function AreGroupsinBoardP1(const Groups,Board:int64): boolean;
var  nI, nM,i: integer;nNxtMves:int64;
begin
  nNxtMves:=Groups and BRD_FULL;
  result:=true;
  repeat      //look whether moves in nNxtMves have a winning line in Player1Brd
    nM := BitScanForward(nNxtMves);
    if nM<7 then break;
    nI:=WLinesP1n[nM][0];
    for i:=1 to nI do
    begin
      if (WLinesP1n[nM][i] and (Board or SET_MASK[nM-7]))=0 then exit;
    end;
    nNxtMves := nNxtMves and RESET_MASK[nM];
  until false;
  result:=false;
end;
function AreGroupsinBoardVP1(const Groups,Board:int64): boolean;
var  nI, nM,i: integer;nNxtMves:int64;
begin
  nNxtMves:=Groups;
  result:=true;
  repeat      //look whether moves in nNxtMves have a winning line in Player1Brd
    nM := BitScanForward(nNxtMves);
    if nM<0 then break;
    nI:=WLinesP1n[nM][0];
    for i:=1 to nI do
    begin
      if (WLinesP1n[nM][i] and (WLinesP1n[nM][i] shr 7))>0 then continue;
      if (WLinesP1n[nM][i] and (Board {or SET_MASK[nM-7] or SET_MASK[nM+7]}))=0 then exit;
    end;
    nNxtMves := nNxtMves and RESET_MASK[nM];
  until false;
  result:=false;
end;
function AreGroupsinBoardBP2(const Groups,Board:int64): boolean;
var  nI, nM,i: integer;nNxtMves:int64;
begin
  nNxtMves:=Groups;
  result:=true;
  repeat      //look whether moves in nNxtMves have a winning line in Player2Brd
    nM := BitScanForward(nNxtMves);
    if nM<0 then break;
    nI:=WLinesP2n[nM][0];
    for i:=1 to nI do
    begin
      if (WLinesP2n[nM][i] and Board)=0 then exit;
    end;
    nNxtMves := nNxtMves and RESET_MASK[nM];
  until false;
  result:=false;
end;
function AreGroupsinBoardP2(const Groups,Board:int64): boolean;
var  nI, nM,i: integer;nNxtMves:int64;
begin
  nNxtMves:=Groups;
  result:=true;
  repeat      //look whether moves in nNxtMves have a winning line in Player2Brd
    nM := BitScanForward(nNxtMves);
    if nM<0 then break;
    nI:=WLinesP2n[nM][0];
    for i:=1 to nI do
    begin
      if (WLinesP2n[nM][i] and (Board or SET_MASK[nM-7]))=0 then exit;
    end;
    nNxtMves := nNxtMves and RESET_MASK[nM];
  until false;
  result:=false;
end;


////////////////////////////////////////////////////////////////////////////////
// Look at the current game board position as stored by the BtBrds and check whether
// Player 1 can win. Return false if Player 2 has at least a draw or can win.
function CanPlayer1Win(adepth:integer): boolean;
var
  nOcpd, nNxtMves, Player1Brd,Player2Brd,Player2BrdVar,Player1BrdVar,
  ClaimEven,After8,AfterE,tmp,tmp1,tmp2,tmp3,tmp4,
  UsedLowinverse,UsedBefore,UsedBaseinverse,UsedByAftereven,UsedVertical,UsedSpecialbefore: Int64;
  AfterEven:array[0..4] of integer;
  Groups:array[0..20] of int64;
  nI, nM,i,nM8,a8Free,k,knM,knI: integer;NoWin,Group:boolean;
begin
  for i:=0 to High(Groups) do Groups[i]:=0;
  result:=true;// k:=0;
  nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  ClaimEven:=BRD_EVENSQRS and not (nOcpd shl 7);//select all even squares where square below is empty
  nNxtMves := not(nOcpd or ClaimEven) and BRD_FULL; //get moves for player1
  Player2Brd:= BtBrd[PT_PLR2] or (ClaimEven and not BtBrd[PT_PLR1]); //set all squares of player 2
    After8:=Player2Brd and not BtBrd[PT_PLR2] and not LAST_ROW ;
    UsedByAftereven:=0;
    AfterEven[0]:=0;
    AfterE:=After8;
    tmp:=After8; // claimed "4 in a row" consisting of empty and already set stones
    repeat       // threats of the opponent above "Aftereven" are sometimes useless
      nM := BitScanForward(tmp);
      if nM<0 then break;
      Ni:=WLinesP2n[nM][0];  //number of wlines
      tmp := tmp and RESET_MASK[nM];
      Group:=false;
      for i:=1 to Ni do
      begin
        if (WLinesP2n[nM][i] and Player2Brd)=WLinesP2n[nM][i] then  //wline which can be completed
        begin                                                       //forms the base of an Aftereven
          Group:=true;
          tmp1:= WLinesP2n[nM][i] and not BtBrd[PT_PLR2];
          a8Free:=BitCount(tmp1); //columns where a  man of the Aftereven group is still missing
          if  a8Free=1 then
          begin
            Player2Brd:=Player2Brd or (BRD_COL shl nM);
            UsedByAftereven:=(BRD_COL shl nM) or UsedByAftereven;
          end;
          if AfterEven[0]>0 then break;  // Aftereven already used
          AfterEven[0]:=a8Free;
          UsedByAftereven:=tmp1 or UsedByAftereven;
          nM8:=nM;
          if  (a8Free=2) or (a8Free=3) or (a8Free=4) then
          repeat
           UsedByAftereven:=UsedByAftereven or (BRD_COL shl nM8);
           AfterEven[a8Free]:=nM8;
           dec(a8Free);
           if a8Free=0 then break;
           tmp1:=tmp1 and RESET_MASK[nM8];
           nM8 := BitScanForward(tmp1);
          until a8Free=0;
        end;
      end;
      if not Group then After8 := After8 and RESET_MASK[nM];
    until nM<0;
  UsedBaseinverse:=0;
  UsedLowinverse:=0;
  UsedBefore:=0;
  UsedVertical:=0;
  UsedSpecialbefore:=0;
  Player2BrdVar:=Player2Brd;
  repeat
    nM := BitScanForward(nNxtMves);
    if nM<0 then break;
    Ni:=WLinesP1n[nM][0];
    for i:=1 to Ni do
    begin
      if (WLinesP1n[nM][i] and Player2Brd)=0 then
      begin
        for k:=0 to High(Groups) do
        begin
          if Groups[k]=0 then break;
          if WLinesP1n[nM][i]=Groups[k] then break;
        end;
        if WLinesP1n[nM][i]=Groups[k] then continue;
        Groups[k]:=WLinesP1n[nM][i];
        assert(k<=High(Groups),'groups');
         if AfterEven[0]=2 then
         if (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[2])>0) then continue;
         if AfterEven[0]=3 then
         if (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[2])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[3])>0) then continue;
         if AfterEven[0]=4 then
         if (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[2])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[3])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[4])>0) then continue;

                                //--------Vertical--------
         tmp:= WLinesP1n[nM][i];
         if tmp and (tmp shl 7)>0 then
         begin
           // Get squares of winning-line which are not empty
           tmp:= WLinesP1n[nM][i] and BtBrd[PT_PLR1];
           if tmp=0 then continue; //all four squares are empty
           // Check whether two already placed stones are directly above each other
           tmp:=tmp and (tmp shl 7);
           // Exclude squares used in previous Baseinverse
           if tmp <> (UsedBaseinverse shr 7) then tmp:=tmp and not (UsedBaseinverse shr 7);
           if BitCount(tmp)>0 then
           begin
             tmp1:=(tmp shl 21) and BRD_FULL; //check moves above for winning lines of player 2
             if not AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1) then
             begin
               UsedBaseinverse:=UsedBaseinverse or (tmp shl 7);
               continue;
             end;
           end;
         end;
                          //--------Baseinverse---------
         // Get squares of winning-line which are empty and directly playable
         tmp:= WLinesP1n[nM][i] and (nOcpd shl 7 or FRST_ROW) and not BtBrd[PT_PLR1];
         // Exclude squares used in previous Baseinverse
         //if tmp <> UsedBaseinverse then
         tmp:=tmp and not UsedBaseinverse and not UsedSpecialbefore;
         // Check whether two stones below are directly above each other which is a vertical threat
         tmp1:=(BtBrd[PT_PLR1] and (BtBrd[PT_PLR1] shl 7)) shl 7;
         // A vertical threat below excludes this square from being used in a Baseinverse
         tmp:=tmp and not tmp1;
         tmp1:=(tmp shl 7) and BRD_FULL; //check moves above for winning lines of player 2
         if BitCount(tmp1)>1 then
         begin
           if (UsedByAftereven and tmp1)=0 then
           begin
// Check whether the stone below belongs to player1 so a verticl thread exist which will
// force a move above the 3rd square and therefore the stone above the forced move cannot be claimed.
             tmp1:=tmp1 or ((tmp and (BtBrd[PT_PLR1] shl 7)) shl  21) and BRD_FULL;
             NoWin:=AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1);
             if not NoWin then
             begin
               UsedBaseinverse:=UsedBaseinverse or tmp;
               Player2BrdVar:=Player2BrdVar and not tmp1;
               continue;
             end; //baseclaim
           end;
         end;
                      //--------Before---------
         if ((WLinesP1n[nM][i] and FRST_ROW)=0) and (WLinesP1n[nM][i] and (BtBrd[PT_PLR1] shl 7)=0) then
         //       wline not in first row        and     no stone from player1 in row below wline
         begin
           //       below wline               exclude claimeven     exclude own stones
           tmp:=(WLinesP1n[nM][i] shr 7) and not Player2BrdVar and not BtBrd[PT_PLR2];
           // all verticals are directly playable ?
           if tmp=tmp and ((nOcpd shl 7) or FRST_ROW) then
           begin
             tmp1:=(tmp or (tmp shl 14)) and BRD_FULL;
             if (tmp1 and UsedByAftereven)>0 then
               tmp1:=tmp1 or (UsedByAftereven and not BRD_EVENSQRS) and BRD_FULL;
             if BitCount(tmp1)=0 then
             begin
               UsedBefore:=WLinesP1n[nM][i] and not BtBrd[PT_PLR1];
               continue;
             end;
             // get moves where Claimeven becomes invalid and check them for winning lines of player1
             if not AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1) then
             begin
               Player2BrdVar:=Player2BrdVar and not tmp1;
               UsedBefore:=WLinesP1n[nM][i] and not BtBrd[PT_PLR1];
               continue;
             end else
             begin    //Specialbefore
                 //        wline           own stones below    square free
               tmp1:=WLinesP1n[nM][i] and (BtBrd[PT_PLR2] shl 7) and not nOcpd;
               tmp3:= (tmp1 shl 7) and BRD_FULL;  // new claimeven
               tmp2:=tmp or tmp3;  //add new claimeven
               if (tmp2 and UsedByAftereven)>0 then
                 tmp2:=tmp2 or (UsedByAftereven and not BRD_EVENSQRS) and BRD_FULL;
               //check whether new claimeven is used in a group
               if (tmp3>0) and ((UsedBaseinverse and tmp1)=0) then
               if not AreGroupsinBoardP1(tmp2,Player2BrdVar and not tmp2) then
               if (UsedSpecialbefore and tmp1)=0 then
               begin
                 UsedSpecialbefore:=UsedSpecialbefore or tmp1;
                 Player2BrdVar:=Player2BrdVar and not tmp2;
                 UsedBefore:=WLinesP1n[nM][i] and not BtBrd[PT_PLR1];
                 continue;
               end;
             end;
           end
         end;
         //--------------Lowinverse + Highinverse------------------------------------
          // Get squares of winning-line where squares below are empty and even
           tmp:= WLinesP1n[nM][i] and not((nOcpd shl 7) or FRST_ROW) and (not BRD_EVENSQRS);
           // Exclude squares used in previous Lowinverse
           tmp2:= (tmp or (tmp shr 14) or (tmp shl 14)) and BRD_FULL;
           if tmp2 <> UsedLowinverse then tmp:=tmp and not UsedLowinverse;
           // Exclude vertical threads
           tmp1:=(BtBrd[PT_PLR1] shl 28) and (BtBrd[PT_PLR1] shl 21) and not (BtBrd[PT_PLR2] shl 14);
           tmp:=tmp and not tmp1;
           if (tmp2 and UsedBefore)=0 then
           if BitCount(tmp)=2 then
           begin
            tmp:=tmp shr 7;
            // get first squares
            tmp3:=SET_MASK[BitScanForward(tmp)];  // get first square
            tmp1:=(tmp3 or ((tmp3 shr 14) and not nOcpd) or (tmp3 shl 14)) and BRD_FULL;
            if (tmp1 and UsedByAftereven)>0 then
               tmp1:=tmp1 or (UsedByAftereven and not BRD_EVENSQRS) and BRD_FULL;
            //groups which contain highinverse of first and second square are solved
            //get highinverse of first square
            tmp3:=(tmp3 shl 14) and BRD_FULL;
            // get second squares
            tmp4:=SET_MASK[BitScanForward(tmp and RESET_MASK[BitScanForward(tmp)])];
            tmp2:=tmp4 or ((tmp4 shr 14) and not nOcpd) or ((tmp4 shl 14) and BRD_FULL);
            if (tmp2 and UsedByAftereven)>0 then
               tmp2:=tmp2 or (UsedByAftereven and not BRD_EVENSQRS) and BRD_FULL;
            //get highinverse of second square
            tmp4:=(tmp4 shl 14) and BRD_FULL;
            if not AreGroupsinBoardVP1(tmp1,Player2BrdVar and not tmp1 and not (tmp2 and not tmp4)) then
            begin
             // check second squares
             if not AreGroupsinBoardVP1(tmp2,Player2BrdVar and not tmp2 and not (tmp1 and not tmp3)) then
             begin
               Player2BrdVar:=Player2BrdVar and not tmp1 and not tmp2;
               UsedLowinverse:=UsedLowinverse or ((tmp shl 7) or (tmp shr 7) or (tmp shl 21)) and BRD_FULL;
               continue;
             end;
            end
           end;

         exit; //it is possible that Player 1 can win.
      end;
    end;
    nNxtMves := nNxtMves and RESET_MASK[nM];
  until nM<0;
  result:=false; //Player 1 cannot win
end;

////////////////////////////////////////////////////////////////////////////////
// Look at the current game board position as stored by the BtBrds and check whether
// it is a winning one. Return whether it is already won for the player with the thread.
function IsBoardWon(const aPlayer,aThreat: integer): boolean;
var
  nOcpd, nNxtMves, Player1Brd,Player2Brd,Player2BrdVar,Player1BrdVar,ClaimEven,After8,AfterE,tmp,tmp1,
  UsedLowinverse,UsedBaseinverse,UsedByAftereven: Int64;
  AfterEven:array[0..4] of integer;
  nI, nM,i,nM8,a8Free,k,knM,knI: integer;NoWin,Group:boolean;
begin
  // Calulate a BitBoard containing only valid moves
  nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  ClaimEven:=BRD_EVENSQRS and not (nOcpd shl 7);//select all even squares where square below is empty
  nNxtMves := not(nOcpd or ClaimEven or (BRD_COL shl (aThreat+7))) and BRD_FULL; //get moves for opponent
  AfterEven[0]:=0;
  if aPlayer=1 then   //Player 1 player1
  begin
    nNxtMves := nNxtMves or (BRD_COL shr (35-aThreat)); //include moves below threat (only Player 1)
    Player1Brd:= BtBrd[PT_PLR1] or (ClaimEven and not BtBrd[PT_PLR2]) or (BRD_COL shl aThreat);
    // remove all empty squares beneath thread square(they take not part in claimeven)
    Player1Brd:=Player1Brd  and  (not (BRD_COL shr (35-aThreat)) or nOcpd);
    // set square below thread if square below is empty and not in first row
    // valid just for player 1 because he can claim uneven squares below threat
    Player1Brd:=Player1Brd  or (SET_MASK[aThreat-7] and not (nOcpd shl 7) and not FRST_ROW) ;
    After8:=Player1Brd and not BtBrd[PT_PLR1] and not LAST_ROW and not (BRD_COL shl (aThreat+7));
    AfterE:=After8;
    tmp:=After8;
    UsedByAftereven:=0;
    repeat
      nM := BitScanForward(tmp);
      if nM<0 then break;
      Ni:=WLinesP1n[nM][0];
      tmp := tmp and RESET_MASK[nM];
      Group:=false;
      for i:=1 to Ni do
      begin
        if (WLinesP1n[nM][i] and Player1Brd)=WLinesP1n[nM][i] then
        begin
          // empty square below threat can not be used in aftereven
          if (WLinesP1n[nM][i] and ((SET_MASK[aThreat] shr 7) and  not BtBrd[PT_PLR1]))>0 then continue;
          Group:=true;
          tmp1:= WLinesP1n[nM][i] and not BtBrd[PT_PLR1];
          a8Free:=BitCount(tmp1); //free places in AfterEven
          if  a8Free=1 then Player1Brd:=Player1Brd or (BRD_COL shl nM);
          if AfterEven[0]>0 then break;
          AfterEven[0]:=a8Free;
          UsedByAftereven:=tmp1;
          nM8:=nM;
          if  (a8Free=2) or (a8Free=3) or (a8Free=4) then
          repeat
           AfterEven[a8Free]:=nM8;
           dec(a8Free);
           if a8Free=0 then break;
           tmp1:=tmp1 and RESET_MASK[nM8];
           nM8 := BitScanForward(tmp1);
          until a8Free=0;
        end;
      end;
      if not Group then After8 := After8 and RESET_MASK[nM];
    until nM<0;
    UsedBaseinverse:=0;
    UsedLowinverse:=0;
    Player1BrdVar:=Player1Brd;
    repeat
      nM := BitScanForward(nNxtMves);
      if nM<0 then break;
      Ni:=WLinesP2n[nM][0];
      for i:=1 to Ni do
      begin
        if (WLinesP2n[nM][i] and Player1Brd)=0 then
        begin
         if AfterEven[0]=2 then
         if (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[2])>0) then continue;
         if AfterEven[0]=3 then
         if (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[2])>0) and
            (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[3])>0) then continue;
         if AfterEven[0]=4 then
         if (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[2])>0) and
            (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[3])>0) and
            (WLinesP2n[nM][i] and (BRD_COL shl AfterEven[4])>0) then continue;
                           //--------Baseinverse---------
         // Get squares of winning-line which are empty and directly playable
         tmp:= WLinesP2n[nM][i] and (nOcpd shl 7 or FRST_ROW) and not BtBrd[PT_PLR2] and RESET_MASK[aThreat];
         // Exclude squares used in previous Baseinverse (if another wline)
         if tmp <> UsedBaseinverse then tmp:=tmp and not UsedBaseinverse;
         // Check two stones below directly above each other which constitutes a vertical threat
         tmp1:=(BtBrd[PT_PLR2] and (BtBrd[PT_PLR2] shl 7)) shl 7;
         // A vertical threat below excludes this square from being used in a Baseinverse
         tmp:=tmp and not tmp1;
         if BitCount(tmp)>1 then
         begin
           tmp1:=(tmp shl 7) and BRD_FULL; //check moves above for winning lines of player 2
           if (UsedByAftereven and tmp1)=0 then
           begin  //moves above already used bei Aftereven ?
             if ((tmp1 shl 7) and SET_MASK[aThreat])>0 then  // can vertical group destroy the threat
               NoWin:=AreGroupsinBoardBP2(tmp1,Player1BrdVar and not tmp1) else //include vertical group (it destroys the threat)
               NoWin:=AreGroupsinBoardP2 (tmp1,Player1BrdVar and not tmp1);
             if not NoWin then
             begin
               UsedBaseinverse:=tmp;
               continue;
             end;
           end;
         end;
                 //--------Vertical--------
         tmp:= WLinesP2n[nM][i];
         if tmp and (tmp shl 7)>0 then
         begin
           // Get squares of winning-line which are not empty
           tmp:= WLinesP2n[nM][i] and BtBrd[PT_PLR2];
           if tmp=0 then continue; //all four squares are empty
           // Check whether two already placed stones directly above each other
           tmp:=tmp and (tmp shl 7);
           // Exclude squares used in previous Baseinverse
           if tmp <> (UsedBaseinverse shr 7) then tmp:=tmp and not (UsedBaseinverse shr 7);
           if BitCount(tmp)>0 then
           begin
             tmp1:=(tmp shl 21) and BRD_FULL; //check moves above for winning lines of player 2
             if (AfterE and tmp1)=0 then
             if not AreGroupsinBoardP2(tmp1,Player1Brd and not tmp1) then
             begin
               UsedBaseinverse:=tmp shl 7;
               continue;
             end;
           end;
         end;
         tmp:=BRD_EVENSQRS and WLinesP2n[nM][i] and not nOcpd and (nOcpd shl 7 or FRST_ROW) and RESET_MASK[aThreat];
         //   even                 wline          empty    below must not be empty or on bottom     not thread
         // Exclude squares used in previous Baseinverse
         if tmp <> UsedBaseinverse then tmp:=tmp and not UsedBaseinverse;
         if BitCount(tmp)>1 then
         begin
           tmp1:=(tmp shl 7) and BRD_FULL;
           if ((tmp1 shl 7) and SET_MASK[aThreat])>0 then  // can vertical group destroy the threat
               NoWin:=AreGroupsinBoardBP2(tmp1,Player1BrdVar and not tmp1) else //include vertical group (it destroys the threat)
               NoWin:=AreGroupsinBoardP2 (tmp1,Player1BrdVar and not tmp1);
           if not NoWin then
           begin
             UsedBaseinverse:=tmp;
             continue;
           end;
         end;


         if ((WLinesP2n[nM][i] and FRST_ROW)=0) and (WLinesP2n[nM][i] and (BtBrd[PT_PLR2] shl 7)=0)
           and (WLinesP2n[nM][i] and SET_MASK[aThreat]=0) then
         //       wline not in first row        and     no stone from player2 in row below wline
         begin  // Before
           tmp:=(WLinesP2n[nM][i] shl 7) and not((Player1Brd shl 14) and Player1Brd) ;
           tmp:=(tmp or (tmp shl 14)) and BRD_FULL;
           // get moves where Claimeven becomes invalid and check them for winning lines of player1
           if not AreGroupsinBoardP2(tmp,Player1Brd and not tmp) then  continue;
         end;
         //--------------Lowinverse------------------------------------
          // Get squares of winning-line where squares below are empty and even
           tmp:= WLinesP2n[nM][i] and not((nOcpd shl 7) or FRST_ROW) and (not BRD_EVENSQRS);
           // Exclude squares used in previous Lowinverse
           if tmp <> UsedLowinverse then tmp:=tmp and not UsedLowinverse;
           // Exclude thread square
           tmp:=tmp and RESET_MASK[aThreat];
           // Exclude vertical threads
           tmp1:=(BtBrd[PT_PLR2] shl 28) and (BtBrd[PT_PLR2] shl 21) and not (BtBrd[PT_PLR1] shl 14);
           tmp:=tmp and not tmp1;
           if BitCount(tmp)=2 then
           begin
            tmp:=tmp shr 7;
            tmp1:=SET_MASK[BitScanForward(tmp)];  // get first square
            tmp1:=tmp1 or ((tmp1 shr 14) and not nOcpd) or ((tmp1 shl 14) and BRD_FULL);
            if not AreGroupsinBoardP2(tmp1,Player1BrdVar and not tmp1) then
            begin
             // get second square
             tmp1:=SET_MASK[BitScanForward(tmp and RESET_MASK[BitScanForward(tmp)])];
             tmp1:=tmp1 or ((tmp1 shr 14) and not nOcpd) or ((tmp1 shl 14) and BRD_FULL);
             if not AreGroupsinBoardP2(tmp1,Player1BrdVar and not tmp1) then
             begin
               Player1BrdVar:=Player1BrdVar and not tmp1;
               UsedLowinverse:=tmp shl 7;
               continue;
             end;
            end
           end;

         if WLinesP2n[nM][i]>=$4000 then  //LowinverseSpecial
         begin
           // Get squares of winning-line where squares below are empty and directly playable
           tmp:= WLinesP2n[nM][i] and not(nOcpd shl 7) and (nOcpd shl 14);
           // Exclude squares used in previous Lowinverse
           if tmp <> UsedLowinverse then tmp:=tmp and not UsedLowinverse;
           // Exclude thread square
           tmp:=tmp and RESET_MASK[aThreat];
           if BitCount(tmp)=2 then
           begin
            tmp:=tmp shl 7;
            tmp1:=SET_MASK[BitScanForward(tmp)];
            tmp1:=(tmp1 or (tmp1 shl 14)) and BRD_FULL;
            if not AreGroupsinBoardP2(tmp1,Player1Brd and not tmp1) then
            begin
             tmp1:=SET_MASK[BitScanForward(tmp and RESET_MASK[BitScanForward(tmp)])];
             tmp1:=(tmp1 or (tmp1 shl 14)) and BRD_FULL;
             if not AreGroupsinBoardP2(tmp1,Player1Brd and not tmp1) then
             begin
               UsedLowinverse:=tmp shr 7;
               continue;
             end;
            end
           end;
         end;
         result:=false;
         exit;      // is not a winning board
        end;
      end;
      nNxtMves := nNxtMves and RESET_MASK[nM];
    until nM<0;
  end else  //Player 2 red
  begin
    Player2Brd:= BtBrd[PT_PLR2] or (ClaimEven and not BtBrd[PT_PLR1]) or (BRD_COL shl aThreat);
    Player2Brd:= Player2Brd and RESET_MASK[aThreat];
    After8:=Player2Brd and not BtBrd[PT_PLR2] and not LAST_ROW and not (BRD_COL shl (aThreat+7));
    UsedByAftereven:=0;
    AfterE:=After8;
    tmp:=After8; // claimed "4 in a row" consisting of empty and already set stones
    repeat       // threats of the opponent above "Aftereven" are sometimes useless
      nM := BitScanForward(tmp);
      if nM<0 then break;
      Ni:=WLinesP2n[nM][0];  //number of wlines
      tmp := tmp and RESET_MASK[nM];
      Group:=false;
      for i:=1 to Ni do
      begin
        if (WLinesP2n[nM][i] and Player2Brd)=WLinesP2n[nM][i] then  //wline which can be completed
        begin                                                       //forms the base of an Aftereven
          Group:=true;
          tmp1:= WLinesP2n[nM][i] and not BtBrd[PT_PLR2];
          a8Free:=BitCount(tmp1); //columns where a  man of the Aftereven group is still missing
          if  a8Free=1 then Player2Brd:=Player2Brd or (BRD_COL shl nM);
          if AfterEven[0]>0 then break;  // Aftereven already used
          AfterEven[0]:=a8Free;
          UsedByAftereven:=tmp1;
          nM8:=nM;
          if  (a8Free=2) or (a8Free=3) or (a8Free=4) then
          repeat
           AfterEven[a8Free]:=nM8;
           dec(a8Free);
           if a8Free=0 then break;
           tmp1:=tmp1 and RESET_MASK[nM8];
           nM8 := BitScanForward(tmp1);
          until a8Free=0;
        end;
      end;
      if not Group then After8 := After8 and RESET_MASK[nM];
    until nM<0;
    UsedBaseinverse:=0;
    UsedLowinverse:=0;
    Player2BrdVar:=Player2Brd;
    repeat      //look whether moves in nNxtMves have a winning line in Player2Brd
      nM := BitScanForward(nNxtMves);
      if nM<0 then break;
      Ni:=WLinesP1n[nM][0];
      for i:=1 to Ni do
      begin
        if (WLinesP1n[nM][i] and Player2Brd)=0 then
        begin
         if AfterEven[0]=2 then
         if (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[2])>0) then continue;
         if AfterEven[0]=3 then
         if (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[2])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[3])>0) then continue;
         if AfterEven[0]=4 then
         if (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[1])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[2])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[3])>0) and
            (WLinesP1n[nM][i] and (BRD_COL shl AfterEven[4])>0) then continue;
                           //--------Baseinverse---------
         // Get squares of winning-line which are empty and directly playable
         tmp:= WLinesP1n[nM][i] and (nOcpd shl 7 or FRST_ROW) and not BtBrd[PT_PLR1] and RESET_MASK[aThreat];
         // Exclude squares used in previous Baseinverse
         if tmp <> UsedBaseinverse then tmp:=tmp and not UsedBaseinverse;
         // Check whether two stones below are directly above each other which is a vertical threat
         tmp1:=(BtBrd[PT_PLR1] and (BtBrd[PT_PLR1] shl 7)) shl 7;
         // A vertical threat below excludes this square from being used in a Baseinverse
         tmp:=tmp and not tmp1;
         if BitCount(tmp)>1 then
         begin
           tmp1:=(tmp shl 7) and BRD_FULL; //check moves above for winning lines of player 2
           if (UsedByAftereven and tmp1)=0 then
           begin  //moves above already used bei Aftereven ?
             if ((tmp1 shl 7) and SET_MASK[aThreat])>0 then  // can vertical group destroy the threat
               NoWin:=AreGroupsinBoardBP1(tmp1,Player2BrdVar and not tmp1) else //include vertical group (it destroys the threat)
               NoWin:=AreGroupsinBoardP1 (tmp1,Player2BrdVar and not tmp1);
             if not NoWin then
             begin
               UsedBaseinverse:=tmp;
               continue;
             end;
           end;
         end;
                                //--------Vertical--------
         tmp:= WLinesP1n[nM][i];
         if tmp and (tmp shl 7)>0 then
         begin
           // Get squares of winning-line which are not empty
           tmp:= WLinesP1n[nM][i] and BtBrd[PT_PLR1];
           if tmp=0 then continue; //all four squares are empty
           // Check whether two already placed stones are directly above each other
           tmp:=tmp and (tmp shl 7);
           // Exclude squares used in previous Baseinverse
           if tmp <> (UsedBaseinverse shr 7) then tmp:=tmp and not (UsedBaseinverse shr 7);
           if BitCount(tmp)>0 then
           begin
             tmp1:=(tmp shl 21) and BRD_FULL; //check moves above for winning lines of player 2
             if (AfterE and tmp1)=0 then
             if not AreGroupsinBoardP1(tmp1,Player2Brd and not tmp1) then
             begin
               UsedBaseinverse:=tmp shl 7;
               continue;
             end;
           end;
         end;
         tmp:=WLinesP1n[nM][i] and BRD_EVENSQRS and not nOcpd and (nOcpd shl 7 or FRST_ROW)and RESET_MASK[aThreat];
         //      wline                 even            empty       below not empty or bottom
         // Exclude squares used in previous Baseinverse
         if tmp <> UsedBaseinverse then tmp:=tmp and not UsedBaseinverse;
         if (BitCount(tmp)>1)  then
         begin
           tmp1:=(tmp shl 7) and BRD_FULL;
           if not AreGroupsinBoardP1(tmp1,Player2Brd and not tmp1) then
           begin
             UsedBaseinverse:=tmp;
             continue;
           end;
         end;
         if ((WLinesP1n[nM][i] and FRST_ROW)=0) and (WLinesP1n[nM][i] and (BtBrd[PT_PLR1] shl 7)=0)
            and (WLinesP1n[nM][i] and SET_MASK[aThreat]=0) then
         //       wline not in first row        and     no stone from player1 in row below wline
         begin  // Before
           tmp:=(WLinesP1n[nM][i] shl 7) and not((Player2Brd shl 14) and Player2Brd) ;
           tmp:=(tmp or (tmp shl 14)) and BRD_FULL;
           // get moves where Claimeven becomes invalid and check them for winning lines of player1
           if not AreGroupsinBoardP1(tmp,Player2Brd and not tmp) then continue;
         end;
         //--------------Lowinverse------------------------------------
          // Get squares of winning-line where squares below are empty and even
           tmp:= WLinesP1n[nM][i] and not((nOcpd shl 7) or FRST_ROW) and (not BRD_EVENSQRS);
           // Exclude squares used in previous Lowinverse
           if tmp <> UsedLowinverse then tmp:=tmp and not UsedLowinverse;
           // Exclude thread square
           tmp:=tmp and RESET_MASK[aThreat];
           // Exclude vertical threads
           tmp1:=(BtBrd[PT_PLR1] shl 28) and (BtBrd[PT_PLR1] shl 21) and not (BtBrd[PT_PLR2] shl 14);
           tmp:=tmp and not tmp1;
           if BitCount(tmp)=2 then
           begin
            tmp:=tmp shr 7;
            tmp1:=SET_MASK[BitScanForward(tmp)];  // get first square
            tmp1:=tmp1 or ((tmp1 shr 14) and not nOcpd) or ((tmp1 shl 14) and BRD_FULL);
            if not AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1) then
            begin
             // get second square
             tmp1:=SET_MASK[BitScanForward(tmp and RESET_MASK[BitScanForward(tmp)])];
             tmp1:=tmp1 or ((tmp1 shr 14) and not nOcpd) or ((tmp1 shl 14) and BRD_FULL);
             if not AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1) then
             begin
               Player2BrdVar:=Player2BrdVar and not tmp1;
               UsedLowinverse:=tmp shl 7;
               continue;
             end;
            end
           end;

         if WLinesP1n[nM][i]>=$4000 then //LowinverseSpecial
         begin
           // Get squares of winning-line where squares below are empty and directly playable
           tmp:= WLinesP1n[nM][i] and not(nOcpd shl 7) and (nOcpd shl 14);
           // Exclude squares used in previous Lowinverse
           if tmp <> UsedLowinverse then tmp:=tmp and not UsedLowinverse;
           // Exclude thread square
           tmp:=tmp and RESET_MASK[aThreat];
           if BitCount(tmp)=2 then
           begin
            tmp:=tmp shl 7;
            tmp1:=SET_MASK[BitScanForward(tmp)];  // get first square
            tmp1:=(tmp1 or (tmp1 shl 14)) and BRD_FULL;
            if not AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1) then
            begin
             // get second square
             tmp1:=SET_MASK[BitScanForward(tmp and RESET_MASK[BitScanForward(tmp)])];
             tmp1:=(tmp1 or (tmp1 shl 14)) and BRD_FULL;
             if not AreGroupsinBoardP1(tmp1,Player2BrdVar and not tmp1) then
             begin
               Player2BrdVar:=Player2BrdVar and not tmp1;
               UsedLowinverse:=tmp shr 7;
               continue;
             end;
            end
           end;
         end;
         result:=false;
         exit;
        end;
      end;
      nNxtMves := nNxtMves and RESET_MASK[nM];
    until nM<0;
  end;
  Result := true;
end;
////////////////////////////////////////////////////////////////////////////////
// Try last moves at the game board and check whether it is a winning one.
// Return the number of moves backwards where the game is won for the player with the thread.
function CheckBackward(const aPlayer,aThreat,aDepth: integer): integer;
var i,BackMoves: integer;
    aBtBrd: TbtBrd;
begin
    aBtBrd:= BtBrd;
    for i:=1 to 9 do
    begin
      BackMoves:=i*2-1;
      if (CrntLvl-ADepth) <= i*2 then break;
      if (aDepth=WLineDepth-i*2) or (aDepth=WLineDepth-i*2+1)  then
      begin;;
        WLinesP1n:=WLinesP1B;
        WLinesP2n:=WLinesP2B;
      end;
      UndoMove(LastMoveList[aDepth+i*2],aPlayer);
      UndoMove(LastMoveList[aDepth+i*2+1],3-aPlayer);
      if CheckMoveForWin(aPlayer,aThreat+7) then  // threat still exists ?
      begin
        if (aThreat<7) or not CheckMovesBelow(aThreat-7,3-aPlayer) or
         ((BtBrd[PT_PLR1] or BtBrd[PT_PLR2]) and (SET_MASK[aThreat-7])>0) then
        if IsBoardWon(aPlayer,aThreat) then
        begin
          continue;
        end;
      end;
      break;
    end;
    BtBrd:= aBtBrd;
    result:=BackMoves;
end;

////////////////////////////////////////////////////////////////////////////////
// Do next possible move at the game board and check whether it is a winning one.
// Return whether the game is won for the player with the thread.
function IsStrategicWin(const aPlayer,aThreat,ADepth: integer): boolean;
var  nI, i, nNM: integer;//sr:boolean;
     nMvLst: array [0..(N_COL - 1)] of integer;
begin
   if IsBoardWon(aPlayer,aThreat) then
   begin
     BackMoves:=-1;
     UndoMove(LastMove,3-aPlayer);
     if aPlayer=2 then
        BackMoves:=BackMoves+0;
     if IsBoardWon(aPlayer,aThreat) then
     begin
       StrategicScore:=true;
       BackMoves:=CheckBackward(aPlayer,aThreat,aDepth);
     end;
     DoMove(LastMove,3-aPlayer);
     result:=true;
     exit;
   end;
   nNM := GetMoves3(nMvLst);
   for i:=0 to nNM-1 do
   begin
      nI := nMvLst[i];
      if nI=aThreat then continue;
      DoMove(nI,aPlayer);
      if IsBoardWon(aPlayer,aThreat) then
      begin // If this board wins the game , undo move and take it.
        result := true;
        UndoMove(nI,aPlayer);
        exit;
      end;
      UndoMove(nI,aPlayer);
    end;
    result := false;
end;

////////////////////////////////////////////////////////////////////////////////
// Look at the current game board position as stored by the BtBrds and fill
// aMoveList with valid cell numbers. Return the number of valid moves
function GetMoves4(var aMoveList: array of integer): integer;
//var  nOcpd, nNxtMves: Int64;
begin
  // Calulate a BitBoard containing only valid moves
      asm
           push    esi
           push    edi
           push    ebx
//       nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
           lea     eax,BtBrd
           mov     ebx,[eax+8]    // BtBrd[PT_PLR1]
           mov     ecx,[eax+$C]
           or      ebx,[eax+$10]  // BtBrd[PT_PLR2]
           or      ecx,[eax+$14]
//        nNxtMves := nOcpd xor ((nOcpd shl 7) or FRST_ROW) and BRD_FULL;
           mov     eax,ebx      // nOcpd
           mov     edx,ecx
           shld    edx,eax,7
           shl     eax,7
           or      eax,FRST_ROW
           and     edx,$3ff
           xor     eax,ebx      // nOcpd
           xor     edx,ecx
           mov     ecx,eax

           xor     ebx,ebx             // reset array index counter
           mov     esi,aMoveList
        //   nM := BitScanForward(nNxtMves);
  @@loopf: mov     edi, ecx
           and     edi, COL_06         // repress moves on the side of the board
           bsf     eax, edi            // dword ptr nNxtMves
           jnz     @@2                 // jump if there is a move on the side
           mov     edi, ecx
           and     edi, MID_COL        // prefer move around the center of the board
           bsf     eax, edi
           jnz     @@2                 // jump if there is a move in the center
           mov     edi, ecx
           and     edi, CENT_COL       // prefer move in the center of the board
           bsf     eax, edi
           jnz     @@2                 // jump if there is a move in the center
           bsf     eax, ecx
           jnz     @@2                 // jump if there is a move

           bsf     eax, edx            // dword ptr nNxtMves+04h
           jz      @@endl              // jump if there is no more move
           btr     edx,eax             // remove move from nNxtMves
           add     eax, 20h
           jmp     @@ef
      @@2: btr     ecx,eax             // remove move from nNxtMves
        //   aMoveList[ebx] := nM;
     @@ef: mov     [esi+ebx*4],eax     // fill move list
           inc     ebx
           cmp     ebx,7               // check array bound
           jnz     @@loopf
   @@endl: mov     result,ebx          // Result = number of valid moves
           POP EBX
           POP EDI
           POP ESI
    end;
end;

////////////////////////////////////////////////////////////////////////////////
// Get possible moves without allowing the opponent to win
// Go through all possible moves and examine if a winning line of the opponent exists.
// If there is one which can be prevented by setting a counter at the right positionb do it.
// If no immediate threat exists find at least one possible move without enabling
// a winning line for the opponent above this move.
// Return -1 There is no move which can prevent a winning line of the opponent.
// Return 0  A stone can be set without the possibility of a winning line of the opponent
// Return x  x is the position of the board where you must move in order to prevent a win of the opponent
function CheckWinOnNextPly1(aPlayer,nNM,LastMove: integer;var aMoveList: array of integer): integer;register;
var BtBrdL,BtBrdH,WLine:integer;
begin
      asm
          PUSH ESI
          PUSH EDI
          PUSH EBX
          mov edi,aPlayer
          CMP EDI,1      //Player 1 or 2
          JNE @@p7
          lea ESI,WLinesP1n
          JMP @@n7
     @@p7:lea ESI,WLinesP2n
     @@n7:LEA EDI,[BtBrd+EDI*8]       // get board of current player
          MOV Wline,ESI

          MOV EAX,DWORD PTR [EDI+4]
          MOV ECX,DWORD PTR [EDI]
          MOV EBX,nNM           // number of moves in aMoveList
          MOV BtBrdH,EAX
          MOV BtBrdL,ECX
          mov result,0
          dec ebx
          jl @@nf        //no moves in aMoveList

  @@loop: mov eax,aMoveList
          mov esi,[eax+ebx*4]  // Load next move position

          mov eax,LastMove     // check whether the winning lines of the last move
          cmp esi,$20          // are covering the actual move
          jnl @@n1
          bt dword ptr [WLINE_MASK+eax*8],esi
          jnc @@k              // skip move because no winningline possible
          jmp @@iloop
  @@n1:   mov ecx,esi
          sub ecx,$20
          bt dword ptr [WLINE_MASK+eax*8+4],ecx
          jnc @@k              // skip move because no winningline possible

  @@iloop:mov ecx,wline
          mov eax,esi          // Position of counter to set
          SHL ESI,4
          LEA ESI,[ecx+ESI*8]  // winning lines for this move
          MOV ECX,[ESI]        // number of winning lines
          TEST ECX,ECX
          JZ  @@k              // no winning lines there

          push ebx
          MOV EDI,BtBrdL
          MOV EBX,BtBrdH
          cmp eax,$20
          jnl @@n5
          bts edi,eax    // set counter low word
          jmp @@a
     @@n5:sub eax,$20
          bts ebx,eax    // set counter high word

      @@a:MOV EAX,DWORD PTR [ESI+ECX*8]    //get winning line low word
          MOV EDX,EDI
          AND EDX,EAX
          CMP EDX,EAX
          JNZ @@e
          MOV EDX,DWORD PTR [ESI+ECX*8+4]  //get winning line high word
          MOV EAX,EBX
          AND EAX,EDX
          CMP EDX,EAX
      @@e:LOOPNZ @@a
          pop ebx
          JNZ   @@k            //jump if not four in a row are found
          mov eax,aMoveList
          mov eax,[eax+ebx*4]  //load position where four in a row found
          mov esi,eax
          cmp result,0         //second possibility of four in a row ?
          jne @@nf             //which cannot be blocked so exit with result=-1
          inc eax              //add 1 to move
          mov result,eax       //return position of first four in a row plus 1
          add esi,7            //try move one row above
          cmp esi,N_SQR        //if there is one
          jl  @@iloop          //do move one row above
      @@k:dec ebx              //do next move in row
          jnl @@loop
          jmp @@exit
     @@nf:mov result,-1        //oppenent has four in a row
  @@exit: POP EBX
          POP EDI
          POP ESI
        end;
end;

////////////////////////////////////////////////////////////////////////////////
// Get possible moves without allowing the opponent to win
// Go through all possible moves and examine if a winning line of the opponent exists.
// If there is one which can be prevented by setting a counter at the right positionb do it.
// If no immediate threat exists find at least one possible move without enabling
// a winning line for the opponent above this move.
// Return -1 There is no move which can prevent a winning line of the opponent.
// Return 0  A stone can be set without the possibility of a winning line of the opponent
// Return x  x is the position of the board where you must move in order to prevent a win of the opponent
function CheckWinOnNextPly2(aPlayer,nNM: integer;var aMoveList: array of integer): integer;register;
var BtBrdL,BtBrdH,WLine:integer;
begin
      asm
          PUSH ESI
          PUSH EDI
          PUSH EBX
          mov edi,aPlayer
          CMP EDI,1      //Player 1 or 2
          JNE @@p7
          lea ESI,WLinesP1n
          JMP @@n7
     @@p7:lea ESI,WLinesP2n
     @@n7:LEA EDI,[BtBrd+EDI*8]       // get board of current player
          MOV Wline,ESI

          MOV EAX,DWORD PTR [EDI+4]
          MOV ECX,DWORD PTR [EDI]
          MOV EBX,nNM           // number of moves in aMoveList
          MOV BtBrdH,EAX
          MOV BtBrdL,ECX
          mov result,0
          dec ebx
          jl @@nf        //no moves in aMoveList

  @@loop: mov eax,aMoveList
          mov esi,[eax+ebx*4]  // Load next move position

          mov eax,LastMove     // check whether the winning lines of the last move
          cmp esi,$20          // are covering the actual move
          jnl @@n1
          bt dword ptr [WLINE_MASK+eax*8],esi
          jnc @@k              // skip move because no winningline possible
          jmp @@iloop
  @@n1:   mov ecx,esi
          sub ecx,$20
          bt dword ptr [WLINE_MASK+eax*8+4],ecx
          jnc @@k              // skip move because no winningline possible

  @@iloop:mov ecx,wline
          mov eax,esi          // Position of counter to set
          SHL ESI,4
          LEA ESI,[ecx+ESI*8]  // winning lines for this move
          MOV ECX,[ESI]        // number of winning lines
          TEST ECX,ECX
          JZ  @@k              // no winning lines there

          push ebx
          MOV EDI,BtBrdL
          MOV EBX,BtBrdH
          cmp eax,$20
          jnl @@n5
          bts edi,eax    // set counter low word
          jmp @@a
     @@n5:sub eax,$20
          bts ebx,eax    // set counter high word

      @@a:MOV EAX,DWORD PTR [ESI+ECX*8]    //get winning line low word
          MOV EDX,EDI
          AND EDX,EAX
          CMP EDX,EAX
          JNZ @@e
          MOV EDX,DWORD PTR [ESI+ECX*8+4]  //get winning line high word
          MOV EAX,EBX
          AND EAX,EDX
          CMP EDX,EAX
      @@e:LOOPNZ @@a
          pop ebx
          JNZ   @@k            //jump if not four in a row are found
          mov eax,aMoveList
          mov eax,[eax+ebx*4]  //load position where four in a row found
          mov esi,eax
          cmp result,0         //second possibility of four in a row ?
          jne @@nf             //which cannot be blocked so exit with result=-1
          inc eax              //add 1 to move
          mov result,eax       //return position of first four in a row plus 1
          add esi,7            //try move one row above
          cmp esi,N_SQR        //if there is one
          jl  @@iloop          //do move one row above
      @@k:dec ebx              //do next move in row
          jnl @@loop
          jmp @@exit
     @@nf:mov result,-1        //oppenent has four in a row
  @@exit: POP EBX
          POP EDI
          POP ESI
        end;
end;
////////////////////////////////////////////////////////////////////////////////
// Go through all possible moves and examine if a winning line of the opponent
// can be prevented by setting a counter at the right position.
// If no immediate threat exists find at least one possible move without enabeling
// a winning line for the opponent above this move.
// Return -1 if a winning line of the opponent can not be prevented.
function CheckWinOnLastPly1( aPlayer,aMove: integer): integer;register;
var  nOcpd, nNxtMves : Int64;
     BtBrdL,BtBrdH,WLine,nNM,nWM:integer;
     aMoveList: array [0..(N_COL - 1)] of integer;
begin
  // Calulate a BitBoard containing only valid moves
  asm  // DoMove(nI3,aPlayer);
        cmp edx,$20   //Pos in edx
        jnl @@n
        bts dword ptr [BtBrd+eax*8],edx   //Player in eax
        jmp @@e
  @@n:  sub edx,$20
        bts dword ptr [BtBrd+eax*8+4],edx
  @@e:
  end;
  nOcpd := BtBrd[PT_PLR1] or BtBrd[PT_PLR2];
  nNxtMves := nOcpd xor ((nOcpd shl 7) or FRST_ROW) and BRD_FULL;
  nOcpd := nNxtMves and WLINE_MASK[aMove];
      asm
           push    esi
           push    edi
           push    ebx
           xor     ebx,ebx
           lea     esi,aMoveList
           mov     ecx,dword ptr nNxtMves
           mov     edx,dword ptr nNxtMves+04h
  @@loopf: bsf     eax, dword ptr nOcpd        // BitScanForward
           jnz     @@2                         // jump if there is a move
           bsf     eax, dword ptr nOcpd+04h
           jz      @@endl                      // jump if there is no more move
           btr     dword ptr nOcpd+04h,eax     // remove move from nOcpd
           btr     edx,eax                     // remove move from nNxtMves
           add     eax, 20h
           jmp     @@ef
      @@2: btr     dword ptr nOcpd,eax         // remove move from nOcpd
           btr     ecx,eax                     // remove move from nNxtMves
     @@ef: mov     [esi+ebx*4],eax             // store move in array
           inc     ebx
           cmp     ebx,7                       // check array bound
           jnz     @@loopf
   @@endl: mov     nWM,ebx  //possible moves covered by winning lines from last move;
 //--------- get remaining moves--------------------
  @@loopk: bsf     eax, ecx                     // BitScanForward
           jnz     @@3                          // jump if there is a move
           bsf     eax, edx
           jz      @@endk                       // jump if there is no more move
           btr     edx,eax                      // remove move from nNxtMves
           add     eax, 20h
           jmp     @@ek
      @@3: btr     ecx,eax                      // remove move from nNxtMves
     @@ek: mov     [esi+ebx*4],eax              // store move in array
           inc     ebx
           cmp     ebx,7                        // check array bound
           jnz     @@loopk
    @@endk:mov     nNM,ebx                      // store number of possible moves;

 //----------Check Board---------------------------

          mov edi,aPlayer
          CMP EDI,1      //Player 1 or 2
          JNE @@p7
          lea ESI,WLinesP1n
          JMP @@n7
     @@p7:lea ESI,WLinesP2n
     @@n7:LEA EDI,[BtBrd+EDI*8]       // get board of current player
          MOV Wline,ESI
          MOV EAX,DWORD PTR [EDI+4]
          MOV ECX,DWORD PTR [EDI]
          MOV EBX,nWM           // number of moves in aMoveList
          MOV BtBrdH,EAX
          MOV BtBrdL,ECX
          mov result,0
          dec ebx
          jl @@fopm        //no moves in aMoveList
  @@loop: lea eax,aMoveList
          mov esi,[eax+ebx*4]  //Load next move position
  @@iloop:mov ecx,wline
          mov eax,esi          //Position of counter to set
          SHL ESI,4
          LEA ESI,[ecx+ESI*8] //winning lines for this move
          MOV ECX,[ESI]       //number of winning lines
          TEST ECX,ECX
          JZ  @@k            //no possible winning lines
          push ebx
          MOV EDI,BtBrdL
          MOV EBX,BtBrdH
          cmp eax,$20
          jnl @@n5
          bts edi,eax    // set counter low word
          jmp @@a
     @@n5:sub eax,$20
          bts ebx,eax    // set counter high word
      @@a:MOV EAX,DWORD PTR [ESI+ECX*8]    //get winning line low word
          MOV EDX,EDI
          AND EDX,EAX
          CMP EDX,EAX
          JNZ @@e
          MOV EDX,DWORD PTR [ESI+ECX*8+4]  //get winning line high word
          MOV EAX,EBX
          AND EAX,EDX
          CMP EDX,EAX
      @@e:LOOPNZ @@a
          pop ebx
          JNZ   @@k            //jump if not four in a row are found
          lea eax,aMoveList
          mov eax,[eax+ebx*4]  //Load position where four in a row found
          mov esi,eax
          cmp result,0         //second possibility of four in a row ?
          jne @@nf             //which cannot be blocked so exit with result=-1
          inc eax              //add 1 to move
          mov result,eax       //return position of first four in a row plus 1
          add esi,7            //try move one row above
          cmp esi,N_SQR        //if there is one
          jl  @@iloop          //do move one row above
      @@k:dec ebx              //else do next move in row
          jnl @@loop
          cmp result,0         //forced move?
          jne @@exit           //if forced move exit

//check whether a stone can be set without enabeling a winning line for the opponent above

  @@fopm: mov ebx,nNM           // number of moves in aMoveList
          dec ebx
  @@lloop:lea eax,aMoveList
          mov esi,[eax+ebx*4]  //Load next move position
          add esi,7            //try move one row above
          cmp esi,N_SQR        //if no move above possible > move below is safe
          jnl  @@exit          //no winning line of opponent above so exit.
          mov ecx,wline
          mov eax,esi          //Position of counter to set
          SHL ESI,4
          LEA ESI,[ecx+ESI*8] //winning lines for this move
          MOV ECX,[ESI]       //number of winning lines
          TEST ECX,ECX
          JZ  @@exit          //no possible winning lines
          push ebx
          MOV EDI,BtBrdL
          MOV EBX,BtBrdH
          cmp eax,$20
          jnl @@ln5
          bts edi,eax    // set counter low word
          jmp @@la
    @@ln5:sub eax,$20
          bts ebx,eax    // set counter high word
     @@la:MOV EAX,DWORD PTR [ESI+ECX*8]    //get winning line low word
          MOV EDX,EDI
          AND EDX,EAX
          CMP EDX,EAX
          JNZ @@le
          MOV EDX,DWORD PTR [ESI+ECX*8+4]  //get winning line high word
          MOV EAX,EBX
          AND EAX,EDX
          CMP EDX,EAX
     @@le:LOOPNZ @@la
          pop ebx
          jnz   @@exit         //jump if not four in a row are found
     @@lk:dec ebx              //do next move in row
          jnl @@lloop
     @@nf:mov result,-1        //oppenent has four in a row
  @@exit: POP EBX
          POP EDI
          POP ESI
        end;                   //result=0 if there are no winning lines
   asm     //UndoMove(nI3,aPlayer);
        mov eax,aMove
        mov edx,aPlayer
        cmp eax,$20
        jnl @@n
        btr dword ptr [BtBrd+edx*8],eax
        jmp @@e
  @@n:  sub eax,$20
        btr dword ptr [BtBrd+edx*8+4],eax
  @@e:
   end;
end;

function NegaMaxBottom(const oPlayer, aBeta: integer): integer;
var
  nI3,k,nNM3,nBV,aPlayer: integer;
  nMvLst3: array [0..(N_COL - 1)] of integer;
begin
  aPlayer:=3-oPlayer;
  nNM3 := GetMoves4(nMvLst3);
  if nNM3=1 then
  begin
    nI3:=nMvLst3[0];
    if (nI3>20) then
    begin
     if CheckMoveForWin(oPlayer,nI3+7) then
     begin
       result := 1;
       exit;
     end;
     if (aBeta>0) and CheckMoveForWin(aPlayer,nI3+14) then
     begin
       result := -1;
       exit;
     end;
     result:=0;
     exit;
    end;
  end;
  k:=CheckWinOnNextPly2(oPlayer,nNM3,nMvLst3); //check opponents possibilitys
  if k<0 then
  begin
    result := 1;   //win of opponent on next ply
    exit;          //no move to prevent it
  end;
  if k>0 then
  begin
    nNM3:=1;              //just one possible move to prevent win of opponent
    nMvLst3[0]:=k-1;      //forced move position
  end;
  nBV := -1;
  while (nNM3 > 0) and (nBV < aBeta) do //try moves on ply
  begin
    dec(nNM3);
    nI3 := nMvLst3[nNM3];
    //opponent on next ply can win above this move so try next move
    if (nI3<(N_SQR-7)) and CheckMoveForWin(oPlayer,nI3+7) then continue;
    if CheckWinOnLastPly1(aPlayer,nI3) < 0 then
    begin
      result := -1;
      exit;               //win on last ply
    end;
    if nBV < 0 then nBV := 0;
  end;
  result:=-nBV;
end;


                                    //0   959      check whether player1 has won
function NegaMaxBottom4(const aPlayer,aAlpha,aBeta: integer): integer;
var                                    //-960   0      check whether red has won
  nI,nNM,nMxAB,nSV,oPlayer: integer;
  nMvLst: array [0..(N_COL - 1)] of integer;
begin                     //oPlayer=red
  oPlayer:=3-aPlayer;
  nNM := GetMoves4(nMvLst);                   //get move list
  if nNM=1 then
  begin
    nI:=nMvLst[0];
    if (nI>13) then
    begin
      if  aBeta=0 then  //just look if red can win
      begin
        if  CheckMoveForWin(oPlayer,nI+7) or
          (CheckMoveForWin(oPlayer,nI+21) and not
           CheckMoveForWin(aPlayer,nI+14)) then
        begin
          result := -1;
        end else result:=0;
        exit;
      end;
      if  aAlpha=0 then  //just look if player1 can win
      begin
       if  CheckMoveForWin(aPlayer,nI+14) and not
           CheckMoveForWin(oPlayer,nI+7) then
       begin
         result := 1;
       end else result:=0;
       exit;
      end;
      if CheckMoveForWin(oPlayer,nI+7) then
      begin
        result := -1;
        exit;
      end;
      if CheckMoveForWin(aPlayer,nI+14) then
      begin
        result := 1;      //Player 2 has won
        exit;
      end;
      if  CheckMoveForWin(oPlayer,nI+21) then
      begin
        result := -1;
        exit;
      end;
      result:=0;
      exit;
    end;
  end;
  nI:=CheckWinOnNextPly2(oPlayer,nNM,nMvLst); //check opponents possibilitys
  if nI<0 then
  begin
    result := -1;        //win of red on next ply
    exit;                //no possible move to prevent a loss
  end;
  if nI>0 then
  begin
    dec(nI);
    LastMove:=nI;         //forced move position
    DoMove(nI,aPlayer);   //set player1 stone
    result:=NegaMaxbottom(aPlayer, -aAlpha);
    UndoMove(nI,aPlayer);
    exit;
  end;
  Result := -1;
  nMxAB := aAlpha;
  nSV := -1;
  while (nNM > 0) and (Result < aBeta) and (Result < 1) do
  begin
    Dec(nNM);
    nI := nMvLst[nNM];
    if (nI>=(N_SQR-7)) or not CheckMoveForWin(oPlayer,nI+7) then //win above >skip move
    begin
      LastMove:=nI;
      DoMove(nI,aPlayer);
      nSV:=NegaMaxbottom(aPlayer, -nMxAB);
      UndoMove(nI,aPlayer);
    end;
    asm
        mov eax,nSV
        cmp eax,Result     //if nSV > Result then
        jng @@1            //begin
        mov Result,eax     //  Result := nSV;
        cmp eax,nMxAB      //  if Result > nMxAB then
        jng @@1
        mov nMxAB,eax      //  nMxAB := Result
    @@1:end;               //end
  end;
end;


function NegaMaxSingleCol(const aPlayer,aAlpha,aBeta,aMove: integer): integer; register;
var                                    //-960   0      check whether red has won
  nI,oPlayer: integer;
begin
   oPlayer:=3-aPlayer;
   result := 1;
   nI:=aMove+7;
   while nI<42 do
   begin
     if CheckMoveForWin(oPlayer,nI) then
     begin
       result:=-result;
       exit;
     end;
     nI:=nI+7;
     if nI>=42 then break;
     if CheckMoveForWin(aPlayer,nI) then  exit;
     nI:=nI+7;
   end;
   result := 0;
end;


// nMxAB is initialized with aAlpha and then holds the best value so far.
// if a draw for red was reached nMxAB is set to 0
// nMxAB is then given to the next iteration in the parameter aBeta
// the next iteration has to look for a red win only.
function NegaMaxAB3test(aDepth, aPlayer, aAlpha, aBeta: integer): integer;
const ForcedMoveDepth=8;
      HashDepth=20 ;
      StrategyDepth=14;
var
  nI,i,k, nNM,nNM1, nBV, nSV, nMxAB, sort,nForcedMove: integer;
  nMvLst: array [0..(N_COL - 1)] of integer;
  nMvLst1: array [0..(N_COL - 1)] of integer;
  Beta:integer;
  PNode:PTransItem;
  sr:boolean;
begin
    BackMoves:=-1;
    nNM := GetMoves4(nMvLst); //get move list
    if nNM=1 then
    begin
      result:=NegaMaxSingleCol(aPlayer, -aBeta, -aAlpha, nMvLst[0] );
      exit;
    end;
    if CancelSearch then begin result:=0;exit;end;
    // Set up variables
    nBV := -1;
    nMxAB := aAlpha;
    if (CrntLvl-aDepth)<HashDepth then
    begin
      PNode:= HashFindPNode;
      if PNode<>nil then
      begin
        if (aAlpha>=PNode^.Alpha) or (PNode^.Score>PNode^.Alpha) then
        if (aBeta<=PNode^.Beta) or (PNode^.Score<PNode^.Beta) then
        begin
          result:=PNode^.Score;
          exit;
        end;
        if (PNode^.Score > nMxAB) and (PNode^.Alpha < 0) then
        begin
          nMxAB:=PNode^.Score;
        end;
       end;
    end;
    k:=CheckWinOnNextPly1(3-aPlayer,nNM,LastMove,nMvLst); //check opponents possibilities
    if k<0 then
    begin
      result := -1;   //win of opponent on next ply
      exit;           //no possible move to prevent a loss
    end;
    if k>0 then
    begin
      nNM:=k-1;   //forced move position
      DoMove(nNM,aPlayer);
      LastMove:=nNM;
      LastMoveList[aDepth]:=nNM;
      BackMoves:=-1;
      if aDepth = 5  then
        result:=-NegaMaxbottom4(3 - aPlayer, -aBeta, -nMxAB)
      else
        result := -NegaMaxAB3test(aDepth - 1, 3 - aPlayer, -aBeta, -nMxAB);
      StrategicScore:=false;  //no strategic win
      UndoMove(nNM,aPlayer);
      if (CrntLvl-ADepth)<HashDepth then
      begin
        if not CancelSearch then HashAdd2(result,nMxAB,aBeta)
      end;
      exit;
    end;
    dec(nNM);
    // Check next ply
    if (aDepth>ForcedMoveDepth) then
    begin
      i:=nNM+1;
      k:=0;
      while i>k do
      begin
        dec(i);
        nI := nMvLst[i];       //if opponent wins above skip this move
        if (nI<(N_SQR-7)) and CheckMoveForWin(3-aPlayer,nI+7) then
        begin
          asm                  //remove loosing move from movelist
            PUSH    ESI
            PUSH    EDI
            MOV     EAX,i;
            LEA     ESI,[nMvLst+EAX *4+4] // point ESI to last dword of source
            LEA     EDI,[nMvLst+EAX *4]   // point EDI to last dword of dest
            MOV     ECX,nNM
            SUB     ECX,EAX               // copy count dwords
            REP     MOVSD
            POP     EDI
            POP     ESI
          end;
          dec(nNM);
          if nNM<0 then
          begin
            result := -1;
            exit;
          end;
          continue;
        end;
        DoMove(nI,aPlayer);
        nNM1 := GetMoves4(nMvLst1);
        // If the opponent can block a win he has to take a forced move.
        nForcedMove:=CheckWinOnNextPly1(aPlayer,nNM1,nI,nMvLst1); //check wheather there is a good move for the opponent of aPlayer
        if nForcedMove<0 then
        begin
          UndoMove(nI,aPlayer);
          result := 1;
          exit;
        end;

        // -----------------------strategic check -----------------------------
        if nForcedMove>0 then   //opponent has only one possible move (nForcedMove+1)
        begin
          UndoMove(nI,aPlayer);
          sort:=FIRST;                //try this move first to force an opponent move
          if (nForcedMove=nI+8) then  //forced move is above last move
          begin
            if CheckMoveForWin(aPlayer,nI+7) then //if forced move is because of vertical threat
            begin
              sort:=LAST;              //try this move last to preserve the threat
              if ((nForcedMove-1) div 7) mod 2 = aPlayer-1 then  //even threat for red;odd threat for player1
              begin
                if IsStrategicWin(aPlayer,nI,aDepth) then  //strategic win
                begin
                  result := 1;
                  exit;
                end;
              end;
            end;
          end;
          //-----------------sort-------------------
          if sort=FIRST then
          begin
            // for k:=i to nNM-1 do nMvLst[k]:=nMvLst[k+1];
            asm
              PUSH    ESI
              PUSH    EDI
              MOV     EAX,i;
              LEA     ESI,[nMvLst+EAX *4 +4] // point ESI to last dword of source
              LEA     EDI,[nMvLst+EAX *4]    // point EDI to last dword of dest
              MOV     ECX,nNM
              SUB     ECX,EAX                // copy count dwords
              REP     MOVSD
              POP     EDI
              POP     ESI
            end;
            nMvLst[nNM]:=nI;
          end;
          if sort=LAST then
          begin
            // for k:=i downto 1 do nMvLst[k]:=nMvLst[k-1];
            asm
              PUSH    ESI
              PUSH    EDI
              MOV     ECX,i;                 // copy count dwords
              LEA     ESI,[nMvLst+ECX *4 -4] // point ESI to last dword of source
              LEA     EDI,[nMvLst+ECX *4]    // point EDI to last dword of dest
              STD
              REP     MOVSD
              CLD
              POP     EDI
              POP     ESI
            end;
            nMvLst[0]:=nI;
            inc(k);inc(i); //adjust loop index
          end;
          //--------------------------end sort--------------------------------
        end;
        // ------------------------end strategic check------------------------

        if nForcedMove=0 then  //no win for aPlayer or forced move for opponent of aPlayer is found.
        begin
          // ---------------look ahead in HashTable---------------------------
          if (CrntLvl-aDepth)<(HashDepth-1) then
          begin
            PNode:= HashFindPNode;
            if PNode<>nil then
            begin
              if  (PNode^.Score < 0) or ((PNode^.Score =0) and (aBeta=0) and (PNode^.Beta>0)) then
              begin
                UndoMove(nI,aPlayer);
                result:=-PNode^.Score;
                exit;
              end;
              if (PNode^.Beta > 0) and (-PNode^.Score > nBV) then
              begin
                nBV:=-PNode^.Score;
              end;
            end;
          end;
          UndoMove(nI,aPlayer);
        end;

      end; //for
    end;
    sr:=true;
    if (aPlayer=1) and (aBeta>0) then
      if (CrntLvl-aDepth)<StrategyDepth then
      begin
        sr:=CanPlayer1Win(adepth);
        if (not sr) and (aAlpha=0) then
        begin
          result:=0;
          exit;
        end;
      end;
    if not sr then Beta:=0 else
      Beta:=aBeta;

    if aDepth=WLineDepth then
    begin;;
      MakeShortWinLinesP;
    end;
    if nBV>nMxAB then
    begin
      nMxAB:=nBV;
    end;
    nBV:= -1;
    // Go through each possible move at this node
    while (nNM >= 0) and (nBV < Beta) and (nBV < 1) do
    begin
      // Extract a move from the move list and play it
      nI := nMvLst[nNM];
      Dec(nNM);
      if (nI<(N_SQR-7)) and CheckMoveForWin(3-aPlayer,nI+7) then continue;
      DoMove(nI,aPlayer);
      // Recursively search values of next moves or get score
      // Return the value of the position at this leaf if required depth reached
      LastMove:=nI;
      LastMoveList[aDepth]:=nI;
      if aDepth =5  then
        nSV:=-NegaMaxbottom4(3 - aPlayer, -Beta, -nMxAB)
      else
        nSV := -NegaMaxAB3test(aDepth - 1, 3 - aPlayer, -Beta, -nMxAB);
      UndoMove(nI,aPlayer);
      if  StrategicScore then
      begin
        dec(BackMoves);
        if BackMoves <= 0 then StrategicScore:=false;
        Result := nSV;
        if aDepth=WLineDepth then
        begin;;
          WLinesP1n:=WLinesP1B;
          WLinesP2n:=WLinesP2B;
        end;
        if not CancelSearch then
          if (CrntLvl-ADepth)<HashDepth then HashAdd2(nSV,-1,1);
        exit;
      end;
      // If a better position is found update alpha-beta
      if nSV > nBV then
      begin
        nBV := nSV;
        if nBV > nMxAB then nMxAB := nBV;
      end;
    end;
    if aDepth=WLineDepth then
    begin;;
      WLinesP1n:=WLinesP1B;
      WLinesP2n:=WLinesP2B;
    end;
    Result := nBV;
    if (CrntLvl-ADepth)<HashDepth then
    begin
      if not CancelSearch then  HashAdd2(nBV,aAlpha,aBeta)
    end;
end;

end.
