{ **************************************************************************** }
{ Project: ConnectFour3D
{ Module:  SearchUtil.pas
{ Author:  Josef Schuetzenberger
{ E-Mail:  schutzenberger@hotmail.com
{ WWW:     http://members.fortunecity.com/schutzenberger
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
unit SearchUtil;

interface
const

  // Connect four game parameters
  N_COL = 7;
  N_ROW = 6;
  N_NUM = 4;
  N_SQR = 42;
  N_WL = 69;

  // Player types
  PT_PLR1 = 1;
  PT_PLR2 = 2;

  // Extreme limits of evaluated score of a position
  INFINITY = High(smallint);
  SCR_WIN =  1000;
  SCR_DRAW = 0;
  SCR_LOSS = -1000;

  // Board constants
  BRD_FULL = $000003FFFFFFFFFF;
  FRST_ROW = $000000000000007F;
  LAST_ROW = $000003F800000000;
  BRD_COL =  $0000000810204081;     //0000 0000 1000 0001 0000 0010 0000 0100 0000 1000 0001
  BRD_EVENSQRS = $000003F80FE03F80; //0011 1111 1000 0000 1111 1110 0000 0011 1111 1000 0000

    // Sort constants
  FIRST = 0;
  LAST = 1;
  NONE = 2;


  // There are 69 unique winning lines of 4 in a row in connect 4
  WIN_LINES: array[0..(N_WL - 1)] of Int64 = (
  $000000000000000F, $000000000000001E, $000000000000003C, $0000000000000078,
  $0000000000000780, $0000000000000F00, $0000000000001E00, $0000000000003C00,
  $000000000003C000, $0000000000078000, $00000000000F0000, $00000000001E0000,
  $0000000001E00000, $0000000003C00000, $0000000007800000, $000000000F000000,
  $00000000F0000000, $00000001E0000000, $00000003C0000000, $0000000780000000,
  $0000007800000000, $000000F000000000, $000001E000000000, $000003C000000000,
  $0000000000204081, $0000000010204080, $0000000810204000, $0000000000408102,
  $0000000020408100, $0000001020408000, $0000000000810204, $0000000040810200,
  $0000002040810000, $0000000001020408, $0000000081020400, $0000004081020000,
  $0000000002040810, $0000000102040800, $0000008102040000, $0000000004081020,
  $0000000204081000, $0000010204080000, $0000000008102040, $0000000408102000,
  $0000020408100000, $0000000001010101, $0000000080808080, $0000004040404000,
  $0000000002020202, $0000000101010100, $0000008080808000, $0000000004040404,
  $0000000202020200, $0000010101010000, $0000000008080808, $0000000404040400,
  $0000020202020000, $0000000000208208, $0000000010410400, $0000000820820000,
  $0000000000410410, $0000000020820800, $0000001041040000, $0000000000820820,
  $0000000041041000, $0000002082080000, $0000000001041040, $0000000082082000,
  $0000004104100000);
  // 69  sorted winning lines of 4 in a row in connect 4
  WIN_LINES1: array[0..(N_WL - 1)] of Int64 = (
  $000000000000000F, $000000000000001E, $000000000000003C, $0000000000000078,
  $0000000000000780, $0000000000000F00, $0000000000001E00, $0000000000003C00,
  $000000000003C000, $0000000000078000, $00000000000F0000, $00000000001E0000,
  $0000000001E00000, $0000000003C00000, $0000000007800000, $000000000F000000,
  $00000000F0000000, $0000000000204081, $0000000010204080, $0000000000408102,
  $0000000020408100, $0000000000810204, $0000000040810200, $0000000001020408,
  $0000000081020400, $0000000002040810, $0000000004081020, $0000000008102040,
  $0000000001010101, $0000000080808080, $0000000002020202, $0000000004040404,
  $0000000008080808, $0000000000208208, $0000000010410400, $0000000000410410,
  $0000000020820800, $0000000000820820, $0000000041041000, $0000000001041040,
  $0000000082082000,
  $0000004040404000, $0000001020408000, $0000000820820000, $0000000404040400,
  $0000000101010100, $0000008080808000, $0000004081020000, $0000000408102000,
  $0000000102040800, $0000001041040000, $0000002082080000, $0000000202020200,
  $0000000810204000, $0000008102040000, $00000001E0000000, $00000003C0000000,
  $0000000780000000, $000000F000000000, $0000007800000000, $0000002040810000,
  $0000000204081000, $0000004104100000,
  $0000010204080000, $0000020408100000, $000003C000000000, $000001E000000000,
  $0000020202020000, $0000010101010000 );
  // Winning Lines Mask for each game cell - Use logical OR to set the appropriate Winning Lines
  WLINE_MASK: array[0..(N_SQR - 1)] of Int64 = (
  $000000000121418F, $000000000242831F, $000000000485063F, $00000000092A8E7F,
  $0000000002450C7E, $00000000048A187C, $0000000009143078, $0000000090A0C781,
  $0000000121418F83, $0000000242A39F8E, $0000000495473F9C, $000000012A8E3F38,
  $00000002450C3E60, $000000048A183C40, $000000485063C081, $00000090A0E7C38A,
  $0000012151CFC715, $0000024AA39FCE2A, $00000095471F9C54, $000001228E1F3828,
  $000002450C1E2040, $0000000811E0C289, $0000005073E1C512, $000000A8E7E38AA4,
  $00000151CFE71549, $000002A38FCE2A12, $000001470F9C1424, $000002040F182848,
  $00000008F0614480, $00000019F0C28900, $00000073F1C55200, $000000E7F38AA480,
  $000001C7E7150900, $00000307C60A1200, $000002078C142400, $0000007830A24000,
  $000000F861448000, $000001F8C2890000, $000003F9C5524000, $000003F182848000,
  $000003E305090000, $000003C60A120000);

 // Set Mask for each game cell - Use logical OR to set the appropriate cell
  SET_MASK: array[0..(N_SQR - 1)] of Int64 = (
  $0000000000000001, $0000000000000002, $0000000000000004, $0000000000000008,
  $0000000000000010, $0000000000000020, $0000000000000040, $0000000000000080,
  $0000000000000100, $0000000000000200, $0000000000000400, $0000000000000800,
  $0000000000001000, $0000000000002000, $0000000000004000, $0000000000008000,
  $0000000000010000, $0000000000020000, $0000000000040000, $0000000000080000,
  $0000000000100000, $0000000000200000, $0000000000400000, $0000000000800000,
  $0000000001000000, $0000000002000000, $0000000004000000, $0000000008000000,
  $0000000010000000, $0000000020000000, $0000000040000000, $0000000080000000,
  $0000000100000000, $0000000200000000, $0000000400000000, $0000000800000000,
  $0000001000000000, $0000002000000000, $0000004000000000, $0000008000000000,
  $0000010000000000, $0000020000000000);

  // Reset Mask for each game cell - Use logical AND to set the appropriate cell
  RESET_MASK: array[0..(N_SQR - 1)] of Int64 = (
  $FFFFFFFFFFFFFFFE, $FFFFFFFFFFFFFFFD, $FFFFFFFFFFFFFFFB, $FFFFFFFFFFFFFFF7,
  $FFFFFFFFFFFFFFEF, $FFFFFFFFFFFFFFDF, $FFFFFFFFFFFFFFBF, $FFFFFFFFFFFFFF7F,
  $FFFFFFFFFFFFFEFF, $FFFFFFFFFFFFFDFF, $FFFFFFFFFFFFFBFF, $FFFFFFFFFFFFF7FF,
  $FFFFFFFFFFFFEFFF, $FFFFFFFFFFFFDFFF, $FFFFFFFFFFFFBFFF, $FFFFFFFFFFFF7FFF,
  $FFFFFFFFFFFEFFFF, $FFFFFFFFFFFDFFFF, $FFFFFFFFFFFBFFFF, $FFFFFFFFFFF7FFFF,
  $FFFFFFFFFFEFFFFF, $FFFFFFFFFFDFFFFF, $FFFFFFFFFFBFFFFF, $FFFFFFFFFF7FFFFF,
  $FFFFFFFFFEFFFFFF, $FFFFFFFFFDFFFFFF, $FFFFFFFFFBFFFFFF, $FFFFFFFFF7FFFFFF,
  $FFFFFFFFEFFFFFFF, $FFFFFFFFDFFFFFFF, $FFFFFFFFBFFFFFFF, $FFFFFFFF7FFFFFFF,
  $FFFFFFFEFFFFFFFF, $FFFFFFFDFFFFFFFF, $FFFFFFFBFFFFFFFF, $FFFFFFF7FFFFFFFF,
  $FFFFFFEFFFFFFFFF, $FFFFFFDFFFFFFFFF, $FFFFFFBFFFFFFFFF, $FFFFFF7FFFFFFFFF,
  $FFFFFEFFFFFFFFFF, $FFFFFDFFFFFFFFFF);

  CENT_COL = $7EFDFBF7; // 0111 1110 1111 1101 1111 1011 1111 0111
  MID_COL = $3C78F1E3;  // 0011 1100 0111 1000 1111 0001 1110 0011
  COL_06 = $183060C1;   // 0001 1000 0011 0000 0110 0000 1100 0001

  COL_01 = $183060C183; //      0001 1000 0011 0000 0110 0000 1100 0001 1000 0011
  COL_56 = $3060C183060;// 0011 0000 0110 0000 1100 0001 1000 0011 0000 0110 0000

  WLineDepth =17;   // depth at which win-lines are recalculated

type
   TBtBrd= array[0..PT_PLR2] of Int64;
   TMove  = record
               Move:integer;     {last Move}
               nBV:integer;      {Minmax-SearchValue}
            end;
   TMoves = array [0..6]of TMove;

var

  // BitBoards of current game position 0=WinLine, 1=Player 1, 2=Player 2
  BtBrd: TbtBrd = (0,0, 0);

  function Sign(const AValue: integer): integer;
  function BitCount(const aBoard: Int64): Integer;
  function BitScanForward(const aBoard: Int64): Integer;
  procedure DoMove(const Pos,aPlayer:integer);
  procedure UndoMove(const Pos,aPlayer:integer);
  function CheckMovesBelow(const Pos,aPlayer:integer):boolean;

implementation

function Sign(const AValue: integer): integer;
begin
  Result := 0;
  if AValue < 0 then
    Result := -1
  else if AValue > 0 then
    Result := 1;
end;

// check whether the 2 stones under the current position are occupied by the Player
function CheckMovesBelow(const Pos,aPlayer:integer):boolean;
asm
        sub eax,7     //calc Pos below
        cmc           //complement carry
        jl @@e        //exit if bottom reached
        cmp eax,$20   //Pos in low or high word
        jnl @@n
        bt dword ptr [BtBrd+edx*8],eax   //Player in edx ?
        jmp @@k
  @@n:  sub eax,$20
        bt dword ptr [BtBrd+edx*8+4],eax
  @@k:  jnc @@e       //exit if there is no move
        sub eax,7     //calc pos below
        cmc           //complement carry
        jl @@e        //exit if bottom reached
        cmp eax,$20   //Pos in low or high word
        jnl @@m
        bt dword ptr [BtBrd+edx*8],eax   //Player in edx  ?
        jmp @@e
  @@m:  sub eax,$20
        bt dword ptr [BtBrd+edx*8+4],eax
  @@e:  rcl eax,1      //transfer carry-flag in result
        and al,$1
end;
procedure DoMove(const Pos,aPlayer:integer);
asm
        cmp eax,$20   //Pos in eax
        jnl @@n
        bts dword ptr [BtBrd+edx*8],eax   //Player in edx
        jmp @@e
  @@n:  sub eax,$20
        bts dword ptr [BtBrd+edx*8+4],eax
  @@e:
end;
procedure UndoMove(const Pos,aPlayer:integer);
asm
//        mov eax,Pos
//        mov edx,aPlayer
//        lea ecx,BtBrd
        cmp eax,$20
        jnl @@n
        btr dword ptr [BtBrd+edx*8],eax
        jmp @@e
  @@n:  sub eax,$20
        btr dword ptr [BtBrd+edx*8+4],eax
  @@e:
end;


function BitCount(const aBoard: Int64): Integer;
asm
       mov     ecx, dword ptr aBoard
       xor     eax, eax
       test    ecx, ecx
       jz      @@1
  @@0: lea     edx, [ecx-1]
       inc     eax
       and     ecx, edx
       jnz     @@0
  @@1: mov     ecx, dword ptr aBoard+04h
       test    ecx, ecx
       jz      @@3
  @@2: lea     edx, [ecx-1]
       inc     eax
       and     ecx, edx
       jnz     @@2
  @@3:
end;


function BitScanForward(const aBoard: Int64): Integer;
asm
       bsf     eax, dword ptr aBoard
       jz      @@0
       jnz     @@2
  @@0: bsf     eax, dword ptr aBoard+04h
       jz      @@1
       add     eax, 20h
       jnz     @@2
  @@1: mov     eax, -1
  @@2:
end;

end.
