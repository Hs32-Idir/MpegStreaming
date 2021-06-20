 (*
         PsyTrance Music Streaming by Hs32-Idir
            -Web : http://wWw.Hs32-Idir.Tk
   |-------------------------------------------------|
   | - Web Music streaming ( Psy Trance )            |
   |   delphi Open source qpplication.               |
   |       : Psychedelic music type :                |
   |-------------------------------------------------|
 *)
program HsIdirStreaming;  (* program name :p *)

{$O+}  //compiler Optimization set "ON"
{$APPTYPE CONSOLE}

uses Windows,Winsock;

var
  WsaData:TWsaData; //general declaration
  hThread:Thandle;

const
  pszStreamingHost = 'eilo.org';          //streamin host/ip address
  dwStreamingPort  =  8000;               //streaming port
  pszStreamingType = 'psychedelic';       //music type default "PsyTrance Music"
  pszFileName:WideString = 'PsyStream';   //default file name & %stream number . MpG
  dwMetaDataTime = 0;                     //time wait between packets default set to 0

function (*convert integer to be visible as WideString*) InttostrW(Int:Integer):Widestring;
begin
  Str(Int,Result);
end;

function (*building first header with spicified data*) BuildPsyHeader(dwFrom:Integer):WideString;
begin
  Result := 'GET /' +pszStreamingType+' HTTP/1.1' + #13#10 +
  'Host: '          +pszStreamingHost + #13#10 +
  'User-Agent: HsIdir/0.0.0' + #13#10 + //user agent default it's  me 'Hs32-Idir'
  'Range: bytes='   +InttostrW(dwFrom)+'-' + #13#10 +
  'Icy-MetaData: '  +InttostrW(dwMetaDataTime) + #13#10 + #13#10;
end;

function (*
           simple thread terminator
           help to close ower process we don't neet to start "taskMgr"
         *) ThreadTerminator(pData:Pointer):Integer; stdcall;
var
  dwExitCode:Cardinal;
begin
  Result := MessageBoxW(0, 'Terminate Streaming','Hs32-Idir PsyTrance',0);
  hThread := 0; //set handle to ZERO
  GetExitCodeThread(GetCurrentThread, dwExitCode); //Get ower thread Exit Code
  //and try terminate it
  if not TerminateThread(GetCurrentThread, dwExitCode) then ExitThread(GetCurrentThread);
end;

procedure (*
             procedure making sockets and writing data to file
             *) GrabPsyTrance(pszHostName:String; dwPort:dword);
var
  sSocket:TSocket;
  HostEnt:PHostEnt;      //needs to make sockets
  SocketAddr:TsockAddrIn;
  pDataRecv:Array[0..4096-1] of Byte;

  pszSendPsyHeader,pszRecvData : String;
  iSendLen,iRecvLen,iFileCount :Integer;

  hFile:Thandle; //needs to create file
  ThreadID:Cardinal;
  BytesWrite,dwFrom:dword;

label JumpAgain;
begin
  dwFrom := 0;
  (*
    build the first header starting from 0
  *)
  WriteLn('* Building a first Header -');
  pszSendPsyHeader := String(BuildPsyHeader( dwFrom div 1 ));
  iFileCount := 0; //%stream number
  //make ower thread terminator 'let's start'
  hThread := CreateThread(nil, 0 , @ThreadTerminator , nil , 0 , ThreadID);
  WriteLn('* Making Terminator thread -');
  JumpAgain : (* make streaming connections socket *)
     WriteLn('* Resolve Remote host -');
     sSocket := Socket(PF_INET,SOCK_STREAM,IPPROTO_TCP);
     SocketAddr.sin_family := AF_INET;//socket type
     SocketAddr.sin_port   := htons(dwPort); //socket port
     SocketAddr.sin_addr.S_addr := inet_addr(PansiChar(pszHostName)); //socket address
     if SocketAddr.sin_addr.S_addr = INADDR_NONE then
     begin  //if there is no ip found 0.0.0.0 then try to resolve IPADDR from host name
      HostEnt := GetHostByName(PansiChar(pszHostName));
      if HostEnt <> nil then SocketAddr.sin_addr.S_addr := LongInt(PlongInt(HostEnt.h_addr_list^)^);
     end;
     //after we got a valid socket then try to connect
     WriteLn('* Try Connectiong to the remote host -');
     if Connect(sSocket , SocketAddr , SizeOf(TSockAddrIn)) = S_OK then
     begin //if succefuly connected send a psy first builded header and waiting for responce
       WriteLn('* Request stream data ... -');
       iSendLen := Send(sSocket , Pointer(pszSendPsyHeader)^ , length(pszSendPsyHeader) + 1 , 0);
       if iSendLen = SOCKET_ERROR   then Exit;
       if iSendLen = INVALID_SOCKET then Exit;
       if iSendLen = 0 then Exit; 
       if iSendLen > 0 then
       begin
         WriteLn('* Writing data into the local file ! -');
         FillChar(pDataRecv, SizeOf(pDataRecv) , #0);
         repeat  //repeat until we got a valid data from server
           iRecvLen := Recv(sSocket , pDataRecv[0], SizeOf(pDataRecv) , 0);
           if iRecvLen > 0 then
           begin 
             SetLength(pszRecvData , iRecvLen);
             (*
               convert ower Recved Bytes to str format to be viewed
               and looking for gotten commands from the server and compare
             *)
             Move(pDataRecv[0] , Pointer(pszRecvData)^ , iRecvLen);
             
             if ( Pos('200 OK',pszRecvData) <> 0 ) and ( Pos('icy-url',pszRecvData) <> 0 ) then
             begin 
               Inc(iFileCount);
               (*
                create and save ower streaming data into file
                compatible with UniCode systems like "Chiness & Arabic"
               *)
               hFile := CreateFileW(PWideChar(pszFileName + IntToStrW(iFileCount) + '.mpG'),
               GENERIC_WRITE,
               FILE_SHARE_WRITE,
               PSECURITYATTRIBUTES(NIL),
               CREATE_ALWAYS,
               FILE_ATTRIBUTE_NORMAL,0);
               if hFile <> INVALID_HANDLE_VALUE then
               begin
                 FillChar(pDataRecv, SizeOf(pDataRecv) , #0);
                 repeat
                   (*
                     repeat writing recved data into file
                     until connection terminated or closed by user "YOU"
                   *)
                   iRecvLen := Recv(sSocket , pDataRecv[0], SizeOf(pDataRecv) , 0);
                   if iRecvLen > 0 then
                   begin //if there is recved bytes "% > 0" then write to file
                     WriteFile(hFile , pDataRecv[0] , iRecvLen , BytesWrite , nil);
                     // including stream position help use to know from where we restart after finish
                     Inc(dwFrom, iRecvLen);
                   end;
                   if iRecvLen = SOCKET_ERROR   then Break;
                   if iRecvLen = INVALID_SOCKET then Break;
                   if hThread  = 0 then Break;
                   if iRecvLen = 0 then Break;
                 until (sSocket = SOCKET_ERROR) or (sSocket = INVALID_SOCKET);
                 WriteLn('* Shutting down sockets !!! -');
                 CloseHandle(hFile);     //close file handle
                 ShutDown(sSocket, SD_BOTH);  //close sockets
                 CloseSocket(sSocket);
                 if hThread = 0 then Break; //check if terminated by UsER
                 //rebuild psy trance header and jump to restart streaming into another file
                 WriteLn('* Rebuilding request Header -');
                 pszSendPsyHeader := BuildPsyHeader(dwFrom - ((dwFrom div 2) div 2)); // -15% needed
                 WriteLn('* Try replay again -');
                 goto JumpAgain; //Jump                      MAKING A VALID POSITION
               end;
             end;
           end;
           WriteLn('* Error shutting down !!! -');
           if iRecvLen = SOCKET_ERROR   then Break;
           if iRecvLen = INVALID_SOCKET then Break;
           if iRecvLen = 0 then Break;
           //wait until thread terminator closed  and break all and Exit to Windows
         until  WaitForSingleObject(hThread,INFINITE) = 0; 
       end;
     end;  //clean up network session
  WriteLn('* Failed or terminated by user -');
  WriteLn('* Clean up session -');
  WSACleanUP();
end;

    (* Program entry point *)
begin
  //network initialization mecanisme creating session
  WriteLn('**************************************************');
  WriteLn('');
  WriteLn('* InitialiZation network session -');
  if WSAStartup($101 , WsaData) <> S_OK then Exit;
  //spicifie szHost and dwPort and start psy trance streaming
  GrabPsyTrance(pszStreamingHost, dwStreamingPort);
  //Exit process to Windows after all done
  WriteLn('* Sleeping beford closing application ... ');
  WriteLn('');
  WriteLn('**************************************************');
  Sleep(9000);
  ExitProcess(0);


end.
