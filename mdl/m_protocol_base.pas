Unit m_Protocol_Base;

{$I M_OPS.PAS}

Interface

Uses
  m_DateTime,
  m_Input,
  m_Socket_Class,
  m_Protocol_Queue;

Type
  RecProtocolStatus = Record
    Protocol    : String[15];
    Sender      : Boolean;
    FilePath    : String;
    FileName    : String;
    FileSize    : Int64;
    Position    : Int64;
    BlockSize   : Word;
    Errors      : Word;
    StartTime   : LongInt;
    StartPos    : Int64;
    LastMessage : String[80];
  End;

  TProtocolStatusProc = Procedure (Starting, Ending: Boolean; Status: RecProtocolStatus);
  TProtocolAbortProc  = Function : Boolean;

  TProtocolBase = Class
    Status      : RecProtocolStatus;
    StatusProc  : TProtocolStatusProc;
    AbortProc   : TProtocolAbortProc;
    Client      : TSocketClass;
    Queue       : TProtocolQueue;
    EndTransfer : Boolean;
    Connected   : Boolean;
    ReceivePath : String;

    Constructor Create (Var C: TSocketClass; Var Q: TProtocolQueue); Virtual;
    Destructor  Destroy; Override;

    Function    AbortTransfer   : Boolean;
    Procedure   StatusUpdate    (Starting, Ending: Boolean);
    Function    ReadByteTimeOut (hSec: LongInt) : SmallInt;
  End;

Implementation

Function NoAbortProc : Boolean;
Begin
  Result := False;
End;

Constructor TProtocolBase.Create (Var C: TSocketClass; Var Q: TProtocolQueue);
Begin
  Client      := C;
  Queue       := Q;
  EndTransfer := False;
  Connected   := True;
  ReceivePath := '';
  StatusProc  := NIL;
  AbortProc   := @NoAbortProc;

  FillChar(Status, SizeOf(Status), 0);
End;

Destructor TProtocolBase.Destroy;
Begin
  Inherited Destroy;
End;

Procedure TProtocolBase.StatusUpdate (Starting, Ending: Boolean);
Begin
  If Assigned(StatusProc) Then
    StatusProc(Starting, Ending, Status);
End;

Function TProtocolBase.ReadByteTimeOut (hSec: LongInt) : SmallInt;
Var
  Res : Byte;
Begin
  Result := -1;

  If Client.DataWaiting Then Begin
    Connected := Client.ReadBuf(Res, 1) <> -1;
    Result    := Res;
  End Else
    Case Client.WaitForData(HSec * 10) of
      -1 : Connected := False;
      0  : ;
    Else
      Client.ReadBuf(Res, 1);
      Result := Res;
    End;
End;

Function TProtocolBase.AbortTransfer : Boolean;
Begin
  If Not EndTransfer Then
    EndTransfer := (Not Connected) or AbortProc;

  AbortTransfer := EndTransfer;
End;

End.
