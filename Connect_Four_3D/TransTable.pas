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
unit TransTable;

interface
uses SearchUtil,classes;
  type
  THList = class(TObject)
  private
    FList: PPointerList;
    FCount: Integer;
    FCapacity: Integer;
    FOnSort: TListSortCompare;
  protected
    function Get(Index: Integer): Pointer;
    procedure Grow; virtual;
    procedure Put(Index: Integer; Item: Pointer);
    procedure SetCapacity(NewCapacity: Integer);
    procedure SetCount(NewCount: Integer);
  public
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure Delete(Index: Integer);
    function Find(const Item: Pointer; var Index: Integer): Boolean;
    procedure Insert(Index: Integer; Item: Pointer);
    property Capacity: Integer read FCapacity write SetCapacity;
    property Count: Integer read FCount write SetCount;
    property Items[Index: Integer]: Pointer read Get write Put; default;
    property OnSort: TListSortCompare read FOnSort write FOnSort;
  end;
const NOTFOUND = $FFFF;
      LISTCOUNT= $FF;
type TListArray= array[0..LISTCOUNT] of THList;
     TTransItem=record
                  Board1:int64;
                  Board2:int64;
                  Score,Alpha,Beta:Shortint;
                end;
     PTransItem = ^TTransItem;

var MirrorDepth:integer;
    ListArray:TListArray;
    HTableItems:integer;
    HTable:array[0..3000000] of TTransItem;
    LastNode:integer=0;

   procedure HashClearn;
   procedure HashCompress;
   function HashFindPNode:PTransItem;
   procedure HashAdd2(const Score,Alpha,Beta:Smallint);
   procedure LoadBookFromResource(FileName:string);

implementation
uses SysUtils,windows;

{ THashList }

destructor THList.Destroy;
begin
  Clear;
end;

procedure THList.Clear;
begin
  SetCount(0);
  SetCapacity(0);
end;

procedure THList.Delete(Index: Integer);
begin
  if (Index < 0) or (Index >= FCount) then exit;
  Dec(FCount);
  if Index < FCount then
    System.Move(FList^[Index + 1], FList^[Index],
      (FCount - Index) * SizeOf(Pointer));
end;

function THList.Get(Index: Integer): Pointer;
begin
  if (Index < 0) or (Index >= FCount) then
  begin
    result:=nil;
    exit;
  end;
  Result := FList^[Index];
end;

procedure THList.Grow;
var
  Delta: Integer;
begin
  if FCapacity > 64 then
    Delta := FCapacity div 2
  else
    if FCapacity > 8 then
      Delta := 16
    else
      Delta := 4;
  SetCapacity(FCapacity + Delta);
end;

procedure THList.Insert(Index: Integer; Item: Pointer);
begin
  if (Index < 0) or (Index > FCount) then exit;
  if FCount = FCapacity then
    Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(Pointer));
  FList^[Index] := Item;
  Inc(FCount);
end;

procedure THList.Put(Index: Integer; Item: Pointer);
begin
  if (Index < 0) or (Index >= FCount) then exit;
  if Item <> FList^[Index] then
  begin
    FList^[Index] := Item;
  end;
end;

procedure THList.SetCapacity(NewCapacity: Integer);
begin
  if (NewCapacity < FCount) or (NewCapacity > MaxListSize) then exit;
  if NewCapacity <> FCapacity then
  begin
    ReallocMem(FList, NewCapacity * SizeOf(Pointer));
    FCapacity := NewCapacity;
  end;
end;

procedure THList.SetCount(NewCount: Integer);
var
  I: Integer;
begin
  if (NewCount < 0) or (NewCount > MaxListSize) then exit;
  if NewCount > FCapacity then
    SetCapacity(NewCount);
  if NewCount > FCount then
    FillChar(FList^[FCount], (NewCount - FCount) * SizeOf(Pointer), 0)
  else
    for I := FCount - 1 downto NewCount do
      Delete(I);
  FCount := NewCount;
end;

function THList.Find(const Item: Pointer; var Index: Integer): Boolean;
var
  L, H, I, C: Integer;
begin
  Result := False;
  L := 0;
  H := FCount - 1;
  if Assigned(FOnSort) then
  while L <= H do
  begin
    I := (L + H) shr 1;
    C := FOnSort(FList^[I], Item);
    if C < 0 then L := I + 1 else
    begin
      H := I - 1;
      if C = 0 then
      begin
        Result := True;
     //   if Duplicates <> dupAccept then L := I;
      end;
    end;
  end;
  Index := L;
end;

Function MirrorBrd(BtBrd:TBtBrd):TBtBrd;
var b:int64;
begin
  b:=BtBrd[1] and (BRD_COL shl 3);
  b:=b or (BtBrd[1] and BRD_COL) shl 6;
  b:=b or (BtBrd[1] and (BRD_COL shl 1)) shl 4;
  b:=b or (BtBrd[1] and (BRD_COL shl 2)) shl 2;
  b:=b or (BtBrd[1] and (BRD_COL shl 4)) shr 2;
  b:=b or (BtBrd[1] and (BRD_COL shl 5)) shr 4;
  b:=b or (BtBrd[1] and (BRD_COL shl 6)) shr 6;
  result[1]:=b;
  b:=BtBrd[2] and (BRD_COL shl 3);
  b:=b or (BtBrd[2] and BRD_COL) shl 6;
  b:=b or (BtBrd[2] and (BRD_COL shl 1)) shl 4;
  b:=b or (BtBrd[2] and (BRD_COL shl 2)) shl 2;
  b:=b or (BtBrd[2] and (BRD_COL shl 4)) shr 2;
  b:=b or (BtBrd[2] and (BRD_COL shl 5)) shr 4;
  b:=b or (BtBrd[2] and (BRD_COL shl 6)) shr 6;
  result[2]:=b;
end;
// check whether a mirror board can be reached from the initial board
procedure CheckMirror;
var b:TBtBrd;
begin
  MirrorDepth:=0;
  b:=MirrorBrd(BtBrd);
  if (b[1] and BtBrd[2])=0 then
    if (b[2] and BtBrd[1])=0 then
      MirrorDepth:=BitCount(BtBrd[1] or BtBrd[2])+10;
end;

function CompareBoards(Item1, Item2: Pointer): Integer;
begin
  result:=0;
  if TTransItem(Item1^).Board1 > TTransItem(Item2^).Board1 then inc(result)
  else
  begin
    if TTransItem(Item1^).Board1 < TTransItem(Item2^).Board1 then dec(result)
    else
    begin
      if TTransItem(Item1^).Board2 > TTransItem(Item2^).Board2 then inc(result)
      else
        if TTransItem(Item1^).Board2 < TTransItem(Item2^).Board2 then dec(result);
    end;
  end;
end;

procedure HashClearn;
var i:integer;aList:^THList;
begin
  CheckMirror;
  for i:=0 to High(ListArray) do
  begin
   HTableItems:=-1;
   aList:=@ListArray[i];
   if Assigned(aList^) then aList^.Free;
   aList^:=THList.Create;
   aList^.Capacity:=10000;
   aList^.OnSort:=@CompareBoards;
  end;
end;

procedure HashCompress;
var i,k,j,x:integer;aList:^THList;
begin
  k:=HTableItems;
  i:=0;
  while i<=k do
  begin
    while (HTable[i].Score=0) and (k>i) do
    begin
      HTable[i]:=HTable[k];
      dec(k);
    end;
    inc(i);
  end;
  dec(i);
  while (i>=0) and (HTable[i].Score=0)  do dec(i);
  HTableItems:=i;

  for i:=0 to High(ListArray) do
  begin
    aList:=@ListArray[i];
    if Assigned(aList^) then aList^.Count:=0 else
      assert(1=2,'Compress-Error (not assigned)');
  end;
  for i:=0 to HTableItems do
  begin
    assert(HTable[i].Score<>0,'Compress Score=0');
    x:=integer(HTable[i].Board1);
    x:=(x xor (x shr 5) xor (x shr 10) xor (x shr 15) xor (x shr 20)) and LISTCOUNT;
    if not Listarray[x].Find(@HTable[i], j) then
      Listarray[x].Insert(j, @HTable[i])
    else
      assert(1=2,'Compress-Error (Duplicate)'+inttostr(i)+'-'+inttostr(x));
  end;
end;

function AddPosition2List(i:integer):Boolean;
var j,x:integer;PNode:PTransItem;
begin
  result:=true;
  x:=integer(HTable[i].Board1);
  x:=(x xor (x shr 5) xor (x shr 10) xor (x shr 15) xor (x shr 20)) and LISTCOUNT ;
  if not Listarray[x].Find(@HTable[i], j) then
    Listarray[x].Insert(j, @HTable[i])
  else
  begin
    PNode:=PTransItem(ListArray[x][j]);
    Assert(Sign(HTable[i].Alpha)<>Sign(HTable[i].Beta),'error');
    Assert(Sign(PNode^.Alpha)<>Sign(PNode^.Beta),'error');
    if Sign(PNode^.Score)<>Sign(HTable[i].Score) then
    begin
      if Sign(PNode^.Score)<0 then Assert((Sign(HTable[i].Alpha)>=0) and (Sign(HTable[i].Score)=0),'Load-error');
      if Sign(PNode^.Score)>0 then Assert((Sign(HTable[i].Beta)<=0) and (Sign(HTable[i].Score)=0),'Load-error');
      if Sign(HTable[i].Score)<0 then Assert((Sign(PNode^.Alpha)>=0) and (Sign(PNode^.Score)=0),'Load-error');
      if Sign(HTable[i].Score)>0 then Assert((Sign(PNode^.Beta)<=0) and (Sign(PNode^.Score)=0),'Load-error');
    end;
    if (Sign(HTable[i].Beta)>0) and (Sign(PNode^.Beta)=0) then
    begin
      PNode^.Beta:=HTable[i].Beta;
      PNode^.Score:=HTable[i].Score;
    end;
    if (Sign(HTable[i].Alpha)<0) and (Sign(PNode^.Alpha)=0) then
    begin
      PNode^.Beta:=HTable[i].Alpha;
      PNode^.Score:=HTable[i].Score;
    end;
    result:=false;
  end;
end;

function HashFindPNode:PTransItem;
var j,x:integer;Node:TTransItem;
begin
  result:=nil;
  Node.Board1:=BtBrd[1];
  Node.Board2:=BtBrd[2];
  x:=integer(BtBrd[1]);
  x:=(x xor (x shr 5) xor (x shr 10) xor (x shr 15) xor (x shr 20)) and LISTCOUNT;
  if ListArray[x].Find(@Node, j) then
  begin
    result:=PTransItem(ListArray[x][j]);
  end;
end;
procedure HashShrink;
var i,k,j,x:integer;aList:^THList;
begin
  k:=HTableItems;
  i:=0;
  while i<=k do
  begin
    while (BitCount(HTable[i].Board1 or HTable[i].Board2)>18) and (k>i) do
    begin
      HTable[i]:=HTable[k];
      dec(k);
    end;
    inc(i);
  end;
  dec(i);
  while BitCount(HTable[i].Board1 or HTable[i].Board2)>18 do dec(i);
  HTableItems:=i;
  for i:=0 to High(ListArray) do
  begin
    aList:=@ListArray[i];
    if Assigned(aList^) then aList^.Count:=0 else
      assert(1=2,'Shrink-Error (not assigned)');
  end;
  for i:=0 to HTableItems do
  begin
    x:=integer(HTable[i].Board1);
    x:=(x xor (x shr 5) xor (x shr 10) xor (x shr 15) xor (x shr 20)) and LISTCOUNT;
    if not Listarray[x].Find(@HTable[i], j) then
      Listarray[x].Insert(j, @HTable[i])
    else
      assert(1=2,'Shrink-Error (Duplicate)'+inttostr(i)+'-'+inttostr(x));
  end;
end;

procedure HashAdd2(const Score,Alpha,Beta:Smallint);
var i,k,j,x:integer;b:TBtBrd;
    PNode:PTransItem;
begin
  i:=High(HTable);
  if i<=(HTableItems+200000) then HashShrink;
  if i<=HTableItems then exit;
  if HTableItems<i then inc(HTableItems);
  i:=HTableItems;
  HTable[i].Board1:=BtBrd[1];
  HTable[i].Board2:=BtBrd[2];
  assert(abs(score)<=1,'score-error');
  HTable[i].Score:=Score;
  if Score<Alpha then HTable[i].Alpha:=Score else
     HTable[i].Alpha:=Alpha;
  if Score>Beta then HTable[i].Beta:=Score else
     HTable[i].Beta:=Beta;
  x:=integer(BtBrd[1]);
  x:=(x xor (x shr 5) xor (x shr 10) xor (x shr 15) xor (x shr 20)) and LISTCOUNT ;
  if not Listarray[x].Find(@HTable[i], j) then
  begin
    Listarray[x].Insert(j, @HTable[i]);
    k:=BitCount(BtBrd[1] or BtBrd[2]);
    if k < MirrorDepth then
    begin
      b:=MirrorBrd(BtBrd);
      i:=High(HTable);
      assert(i>HTableItems,'Hashlength Error');
      if HTableItems<i then inc(HTableItems);
      i:=HTableItems;
      HTable[i].Board1:=B[1];
      HTable[i].Board2:=B[2];
      x:=integer(B[1]);
      x:=(x xor (x shr 5) xor (x shr 10) xor (x shr 15) xor (x shr 20)) and LISTCOUNT;
      HTable[i].Score:=Score;
      if Score<Alpha then HTable[i].Alpha:=Score else
         HTable[i].Alpha:=Alpha;
      if Score>Beta then HTable[i].Beta:=Score else
         HTable[i].Beta:=Beta;
      if not Listarray[x].Find(@HTable[i], j) then
      begin
        Listarray[x].Insert(j, @HTable[i]);
      end else
        dec(HTableItems);
    end;
  end else
  begin
    dec(HTableItems);
    PNode:=PTransItem(ListArray[x][j]);
    if (Alpha<PNode^.Alpha) then
    begin
      if Score<PNode^.Alpha then PNode^.Score:=Score;
      PNode^.Alpha:=Alpha;
    end;
    if (Beta>PNode^.Beta) then
    begin
      if Score>PNode^.Beta then PNode^.Score:=Score;
      PNode^.Beta:=Beta;
    end;
  end;
end;
//--------------------------------------------------------
//Convert list of moves as they are played to a bitboard
function Moves2BitBoard(MoveList:integer):TBtBrd;
var i,k,j:integer;Board,Board1,Board2:int64;
begin
  Board1:=0;
  Board2:=0;
  for i:=0 to 8 do
  begin
    j:=(MoveList shr (i*3)) and $7;
    k:=BitCount((Board1 or Board2) and (BRD_COL shl j));
    Board := Board1 or SET_MASK[k * 7 + j];
    Board1:=Board2;
    Board2:=Board;
  end;
  result[PT_PLR1]:=Board2;
  result[PT_PLR2]:=Board1;
end;

procedure LoadResourceFile(aFile:string; var MemoryStream:TMemoryStream);
function ExtractFileRoot(FileName: String): String;
begin
  FileName := ExtractFileName(FileName);
  Result := Copy(FileName, 1, Pos(ExtractFileExt(FileName), FileName)-1);
end;

var
  HResInfo:HRSRC;
  HGlobal: THandle;
  Buffer: pchar;
  Ext:string;
begin
  if (MemoryStream = nil) then
    MemoryStream := TMemoryStream.Create;
  ext:=Uppercase(ExtractFileExt(aFile));
  ext:=Copy(ext, 2, 99);
  aFile := ExtractFileRoot(aFile);
  HResInfo := FindResource(HInstance, PChar(aFile), PChar(ext));
  HGlobal := LoadResource(HInstance, HResInfo);
  if HGlobal = 0 then
    raise EResNotFound.Create('Cannot load resource: ' + aFile);
  Buffer := LockResource(HGlobal);
  MemoryStream.Clear;
  MemoryStream.WriteBuffer(Buffer[0], SizeOfResource(HInstance, HResInfo));
  MemoryStream.Seek(0,0);
  UnlockResource(HGlobal);
  FreeResource(HGlobal);
end;

procedure LoadBookFromResource(FileName:string);
var i,k:integer;BtBrd1,BtBrd2:TBtBrd;
    Score,Alpha,Beta:Smallint;c:cardinal;
    MemoryStream:TMemoryStream ;
begin
  MemoryStream := TMemoryStream.Create;
  LoadResourceFile(FileName,MemoryStream);
  while true do
  begin
    assert(High(HTable)>HTableItems,'Hashlength Error');
    if HTableItems<High(HTable) then inc(HTableItems);
    i:=HTableItems;
    if MemoryStream.Read(c,4)<4 then break;
    Score:=0;
    if (c and $80000000)>0 then Score:=1;
    if (c and $40000000)>0 then Score:=-1;
    c:=c and $07FFFFFF;
    BtBrd1:=Moves2BitBoard(c);
    Alpha:=-1;
    Beta:=1;
    HTable[i].Board1:=BtBrd1[1];
    HTable[i].Board2:=BtBrd1[2];
    HTable[i].Score:=Sign(Score);
    HTable[i].Alpha:=Sign(Alpha);
    HTable[i].Beta:=Sign(Beta);
    Assert(Sign(HTable[i].Alpha)<>Sign(HTable[i].Beta),'error');
    if not AddPosition2List(i) then dec(HTableItems);
    assert(High(HTable)>HTableItems,'Hashlength Error');
    if HTableItems<High(HTable) then inc(HTableItems);
    k:=HTableItems;
    BtBrd2[1]:=HTable[i].Board1;
    BtBrd2[2]:=HTable[i].Board2;
    BtBrd1:=MirrorBrd(BtBrd2);
    if (BtBrd1[1]=BtBrd2[1]) and (BtBrd1[2]=BtBrd2[2]) then
    begin
      dec(HTableItems);
      continue;
    end;
    HTable[k].Board1:=BtBrd1[1];
    HTable[k].Board2:=BtBrd1[2];
    HTable[k].Score:=HTable[i].Score;
    HTable[k].Alpha:=HTable[i].Alpha;
    HTable[k].Beta:=HTable[i].Beta;
    if not AddPosition2List(k) then dec(HTableItems);
  end;
  dec(HTableItems);
  MemoryStream.Free;
end;

end.
