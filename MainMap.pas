unit MainMap;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.Generics.Collections, System.JSON, System.DateUtils,
  FMX.Types, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMXTee.Series,
  FMXTee.Engine, FMXTee.Chart, FMX.Platform, FMX.StdCtrls, FMX.Menus,
  FMX.Controls, FMXTee.Procs,
  IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer, idglobal,
  IdContext, System.Syncobjs;

type
  TMapDisplay = class(TForm)
    Refresh_display: TTimer;
    Chart1: TChart;
    Series1: TLineSeries;
    Series2: TPointSeries;
    MenuBar1: TMenuBar;
    Removed: TMenuItem;
    IdTCPServer1: TIdTCPServer;
    Worker_loc: TTimer;
    Update_notifications: TTimer;
    Ack_Wk: TTimer;
    Send_Notify: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Chart1ClickSeries(Sender: TCustomChart; Series: TChartSeries;
      ValueIndex: Integer; Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    procedure Refresh_displayTimer(Sender: TObject);
    procedure update_line(s1: Integer; s2: Integer);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure Worker_locTimer(Sender: TObject);
    procedure Update_notificationsTimer(Sender: TObject);
    procedure Ack_WkTimer(Sender: TObject);
    procedure Send_NotifyTimer(Sender: TObject);
    procedure RemovedClick(Sender: TObject);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Chart1KeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure Chart1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Single);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

  RouteMapdata = record
    Route_no: Word;
    st_lat: double;
    st_lon: double;
    st_mark: boolean;
  end;

  workerdata = record
    IMEI_no: string[16];
    p_lat: double;
    p_lon: double;
    Route_no: Word;
    attachment: boolean;
    context: TIdContext;
    seriesno: Word;
  end;

  station = record
    station_id: Word;
    Station_name: string[20];
  end;

  Train_Record = record
    station_id: Word;
    train_move: boolean;
    time: string;
    Route_no: Word;
    Line_no: Word;
  end;

  notification_record = record
    context: TIdContext;
    IMEI_no: string[16];
    station_id: Word;
    start_time: string[24];
    Line_no: Word;
    response_time: string[30];
    status: boolean;
    count: Word;
  end;

procedure update_worker_buf(data: String; ipadress: string; portno: Word);
procedure update_active_workers(p_route, n_route, index: Word);
procedure update_Notification_buf(train_data: String);
procedure Disconnectallclients;

const
  max_ippacket_size = 65535;
  tr_recpacket_size = 58;
  acksize = 70;
  select_size = 5;
  host_len = 15;
  port_len = 2;
  workerlocsize = 76;

var
  MapDisplay: TMapDisplay;
  st_buf: array of station;
  Map_buf: array of RouteMapdata;
  worker_buf: array of workerdata;
  active_workers: array of array of Word;
  TempRecvBuf_loc: array [0 .. $FFFF] of Byte;
  TempRecvBuf_train: array [0 .. $FFFF] of Byte;
  TempRecvBuf_ACK: array [0 .. $FFFF] of Byte;
  notification_buf: array of notification_record;
  temp: Word = 0;
  flag: boolean = false;
  number_of_routes: Word;
  seriesindex2, SeriesIndex1: Integer;
  sd: TDictionary<Integer, TLineSeries>;
  point_idx, point_idxT, point_idxA: Word;
  Xmin, xmax, Ymin, ymax: double;
  CriticalSection, CriticalSection1: TCriticalSection;
  MouseInLegend: boolean;

implementation

{$R *.fmx}

uses toggle, Detachedpersons;

procedure TMapDisplay.Chart1ClickSeries(Sender: TCustomChart;
  Series: TChartSeries; ValueIndex: Integer; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  previous_route: Word;
  scpoint2: TPointf;
begin
  try
    SeriesIndex1 := Series1.Clicked(X, Y);
    seriesindex2 := Series2.Clicked(X, Y);
    if (seriesindex2 <> -1) then
    begin
      if (worker_buf[seriesindex2 + 1].attachment = false) then
      begin
        temp := (seriesindex2 + 1);
        flag := true;
        Series2.Pointer[seriesindex2].Color := TAlphaColorRec.red;
        Series2.Pointer[seriesindex2].Size := select_size;
      end
      else
      begin
        temp := (seriesindex2 + 1);
        flag := false;
        scpoint2.X := X;
        scpoint2.Y := Y;
        Series2.Pointer[seriesindex2].Color := TAlphaColorRec.red;
        Series2.Pointer[seriesindex2].Size := select_size;
        scpoint2 := MapDisplay.ClientToScreen(scpoint2); // TChart(sender).
        click_tag.Left := Round(scpoint2.X);
        click_tag.Top := Round(scpoint2.Y);
        click_tag.Label1.Text := 'person ' + inttostr(seriesindex2 + 1) +
          ' is in route : ' + inttostr(worker_buf[seriesindex2 + 1].Route_no);
        click_tag.Show;
      end;
    end;
    if (SeriesIndex1 <> -1) then
    begin
      if (flag = true) then
      begin
        previous_route := worker_buf[temp].Route_no;
        worker_buf[temp].Route_no := Map_buf[SeriesIndex1 + 1].Route_no;
        worker_buf[temp].attachment := true;
        update_active_workers(previous_route, worker_buf[temp].Route_no, temp);
        update_line(SeriesIndex1 + 1, temp);
        worker_buf[temp].seriesno := SeriesIndex1 + 1;
        ShowMessage('Person : ' + inttostr(temp) + ' attached to Route : ' +
          inttostr(worker_buf[temp].Route_no));
        flag := false;
      end
      else
        ShowMessage('please click on the person to attach');
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Chart Series click ' + ' Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
end;

procedure TMapDisplay.Chart1KeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if MouseInLegend then
    case Key of
      TeeKey_Down:
        if ((Chart1.Legend.lastvalue + 1) < length(worker_buf) - 1) then
        begin
          ShowMessage(inttostr((Chart1.Legend.lastvalue + 1)));
          Chart1.Legend.FirstValue := Chart1.Legend.FirstValue + 1;
        end;
      TeeKey_Up:
        if (Chart1.Legend.FirstValue >= 1) then
          Chart1.Legend.FirstValue := Chart1.Legend.FirstValue - 1;
    end;
end;

procedure TMapDisplay.Chart1MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Single);
begin
  MouseInLegend := (Chart1.Legend.Clicked(Round(X), Round(Y)) > -1);
end;

procedure TMapDisplay.update_line(s1: Integer; s2: Integer);
var
  myseries, myseries1: TLineSeries;
begin
  try
    if (sd.ContainsKey(s2)) = true then
    begin
      sd.TryGetValue(s2, myseries1);
      myseries := myseries1;
      myseries.Clear;
      if worker_buf[s2].Route_no <> 0 then
      begin
        if worker_buf[s2].context = nil then
        begin
          myseries.SeriesColor := TAlphaColorRec.Brown;
          Series2.Pointer[s2 - 1].Color := TAlphaColorRec.gold;
          Chart1.Legend.Item[s2 - 1].Text := inttostr(s2) + ' disconnected';
        end
        else
        begin
          myseries.SeriesColor := TAlphaColorRec.Navy;
          Series2.Pointer[s2 - 1].Color := TAlphaColorRec.Green;
          Chart1.Legend.Item[s2 - 1].Text := inttostr(s2) + ' connected';
        end;
        myseries.AddXY(Map_buf[s1].st_lat, Map_buf[s1].st_lon);
        myseries.AddXY(worker_buf[s2].p_lat, worker_buf[s2].p_lon);
      end
      else
        sd.remove(s2);
      sd.TrimExcess;
    end
    else
    begin
      myseries := TLineSeries.Create(self);
      myseries.ParentChart := Chart1;
      if worker_buf[s2].context = nil then
      begin
        myseries.SeriesColor := TAlphaColorRec.Brown;
        Series2.Pointer[s2 - 1].Color := TAlphaColorRec.gold;
        Chart1.Legend.Item[s2 - 1].Text := inttostr(s2) + ' disconnected';
      end
      else
      begin
        myseries.SeriesColor := TAlphaColorRec.Navy;
        Series2.Pointer[s2 - 1].Color := TAlphaColorRec.Green;
        Chart1.Legend.Item[s2 - 1].Text := inttostr(s2) + ' connected';
      end;
      myseries.ClickableLine := false;
      myseries.LinePen.SmallDots := true;
      myseries.LinePen.SmallSpace := 1;
      myseries.AddXY(Map_buf[s1].st_lat, Map_buf[s1].st_lon);
      myseries.AddXY(worker_buf[s2].p_lat, worker_buf[s2].p_lon);
      sd.Add(s2, myseries);
    end
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Update Line ' + ' Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
end;

procedure TMapDisplay.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Disconnectallclients;
end;

procedure TMapDisplay.FormCreate(Sender: TObject);
var
  i, ct: Word;
  F: File;
  N: Integer;
  fileName: string;
begin
  MouseInLegend := false;
  point_idx := 0;
  point_idxT := 0;
  point_idxA := 0;
  Refresh_display.Enabled := true;
  Series2.ClickTolerance := 4;
  CriticalSection := TCriticalSection.Create;
  CriticalSection1 := TCriticalSection.Create;
  try
    sd := TDictionary<Integer, TLineSeries>.Create();
    ct := 0;
    // station details from file
    fileName := 'C:\NMRH\WAS\display_data\Route_Map.dat';
    if FileExists(fileName) then
    begin
      AssignFile(F, fileName);
{$I-} Reset(F, Sizeof(RouteMapdata)); {$I+}
      if IoResult = 0 then
      begin
        SetLength(Map_buf, 1);
        i := 1;
        while not Eof(F) do
        begin
          SetLength(Map_buf, length(Map_buf) + 1);
{$I-} BlockRead(F, Map_buf[i], 1, N); {$I+}
          i := i + 1;
        end;
{$I-} CloseFile(F); {$I+}
      End;
    end
    else
      ShowMessage
        ('Route_Map.dat file missing in the path C:\NMRH\WAS\display_data');

    // workers details from file
    fileName := 'C:\NMRH\WAS\display_data\Persons.dat';
    if FileExists(fileName) then
    begin
      AssignFile(F, fileName);
{$I-} Reset(F, 16); {$I+}
      if IoResult = 0 then
      begin
        SetLength(worker_buf, 1);
        i := 1;
        while not Eof(F) do
        begin
          SetLength(worker_buf, length(worker_buf) + 1);
{$I-} BlockRead(F, worker_buf[i], 1, N); {$I+}
          i := i + 1;
        end;
{$I-} CloseFile(F); {$I+}
      End;
    end
    else
      ShowMessage
        ('worker_points.dat file missing in the path C:\NMRH\WAS\display_data');

    // station details from file
    fileName := 'C:\NMRH\WAS\display_data\stations.dat';
    if FileExists(fileName) then
    begin
      AssignFile(F, fileName);
{$I-} Reset(F, Sizeof(station)); {$I+}
      if IoResult = 0 then
      begin
        SetLength(st_buf, 0);
        i := 0;
        while not Eof(F) do
        begin
          SetLength(st_buf, length(st_buf) + 1);
{$I-} BlockRead(F, st_buf[i], 1, N); {$I+}
          i := i + 1;
        end;
{$I-} CloseFile(F); {$I+}
      End;
    end
    else
      ShowMessage
        ('Stations.dat file missing in the path C:\NMRH\WAS\display_data');

    // settig the scale values to upto 8 decimal points
    Chart1.LeftAxis.AxisValuesFormat := '0.########';
    Chart1.bottomAxis.AxisValuesFormat := '0.########';

    // loading station details from
    for i := 1 to length(Map_buf) - 1 do
    begin
      Series1.AddXY(Map_buf[i].st_lat, Map_buf[i].st_lon,
        inttostr(Map_buf[i].Route_no));
    end;

    // fixing the axis scale to min max scale of series-1
    Xmin := Chart1.Series[0].MinXValue;
    xmax := Chart1.Series[0].MaxXValue;
    Ymin := Chart1.Series[0].MinYValue;
    ymax := Chart1.Series[0].MaxYValue;
//     Chart1.Axes.Bottom.SetMinMax(Xmin - 0.01, xmax + 0.01);// 0.01 is for tolarance at graph start & end points
//     Chart1.Axes.Left.SetMinMax(Ymin - 0.01, ymax + 0.01);

//    worker_buf[1].p_lat := 22.68271044;
//    worker_buf[1].p_lon := 88.34608296;
    // worker_buf[1].IMEI_no:='12345612343';
    // worker_buf[1].IP_no:='10.0.1.246';
//    worker_buf[2].p_lat := 22.69271044;
//    worker_buf[2].p_lon := 88.34608296;
    // SetLength(worker_buf, 60);
    // for I := 4 to 10 do
    // worker_buf[i].imei_no := '88.34608296';

    // loading worker details from sheet-2 of excel
    for i := 1 to length(worker_buf) - 1 do
    begin
      Series2.AddXY(worker_buf[i].p_lat, worker_buf[i].p_lon);
    end;
    // to hide the intermideate points and marks
    for i := 1 to length(Map_buf) do
    begin
      if (Map_buf[i].st_mark <> true) then
      begin
        Series1.Pointer.style := psNothing;
        Series1.Marks[i - 1].Visible := false;
      end
      else
      begin
        Series1.Pointer[i - 1].style := pscircle;
      end;
    end;

    // set the number of routes length
    for i := 1 to length(Map_buf) do
      if Map_buf[i].st_mark = true then
        inc(ct);
    SetLength(active_workers, ct);

    IdTCPServer1.Active := true;
    if IdTCPServer1.Active then
      ShowMessage('server is active')
    else
      ShowMessage('server is not active');

    Send_Notify.Enabled := true;
    Ack_Wk.Enabled := true;
    Update_notifications.Enabled := true;
    Worker_loc.Enabled := true;
  except
    on e: Exception do
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        'Module : Form Create ' + ' Time :' +
        FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
        'C:\NMRH\WAS\Exceptions.txt');
  end;
end;

procedure TMapDisplay.IdTCPServer1Disconnect(AContext: TIdContext);
var
  i, j: Word;
begin
  for i := 1 to length(worker_buf) - 1 do
  begin
    if (worker_buf[i].context <> nil) then
    begin
      if (worker_buf[i].context.Binding.PeerIP = AContext.Binding.PeerIP) then
        if (worker_buf[i].context.Binding.PeerPort = AContext.Binding.PeerPort)
        then
        begin
          worker_buf[i].context := nil;
          if (length(notification_buf) <> 0) then
          begin
            for j := 0 to length(notification_buf) - 1 do
            begin
              if (notification_buf[j].IMEI_no = worker_buf[i].IMEI_no) then
              begin
                notification_buf[j].context := nil;
              end;
            end;
          end;
          break
        end;
    end;
  end;
end;

procedure TMapDisplay.IdTCPServer1Execute(AContext: TIdContext);
Var
  RxBufSize, count, len: Integer;
  RxBufStr: TIDbytes;
  recived_cnt: Word;
  host, port: TBytes;
  s: string;
  i: Integer;
  No_ofpacket, X: Integer;
begin
  RxBufSize := AContext.Connection.IOHandler.InputBuffer.Size;
  If RxBufSize > 0 Then
  Begin
    SetLength(RxBufStr, RxBufSize);
    case AContext.Binding.port of
      4090: // to recive data from workers
        begin
          try
            recived_cnt := 0;
            SetLength(host, host_len);
            SetLength(port, port_len);
            host := TEncoding.UTF8.GetBytes(AContext.Binding.PeerIP);
            port[0] := lo(AContext.Binding.PeerPort);
            port[1] := hi(AContext.Binding.PeerPort);
            AContext.Connection.IOHandler.ReadBytes(RxBufStr, RxBufSize, false);
            // s := TEncoding.UTF8.GetString(RxBufStr);
            len := workerlocsize; // workerlocsize : 76
            while (RxBufSize >= acksize) do // acksize : 70
            begin
              CriticalSection.Enter;
              if (RxBufStr[recived_cnt + 74] = 125) then // workerlocsize-2 : 74
              begin
                move(RxBufStr[recived_cnt], TempRecvBuf_loc[point_idx], len);
                s := TEncoding.UTF8.GetString(TBytes(RxBufStr),
                  recived_cnt, len);
                inc(recived_cnt, len);
                inc(point_idx, len);
                move(host[0], TempRecvBuf_loc[point_idx], host_len);
                inc(point_idx, host_len); // host :15
                move(port[0], TempRecvBuf_loc[point_idx], port_len);
                inc(point_idx, port_len); // port:2
                CriticalSection.Leave;
                dec(RxBufSize, len);
                AppendTextFileForbackupFail_Updation
                  (s + ' Time : ' + FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ',
                  Now), 'C:\NMRH\WAS\LOCATION_Recived.txt');
              end
              else
              begin
                move(RxBufStr[recived_cnt],TempRecvBuf_ACK[point_idxA], acksize);
                inc(point_idxA, acksize); // acksize : 70
                CriticalSection.Leave;
                s := TEncoding.UTF8.GetString(TBytes(RxBufStr),recived_cnt, acksize);
                inc(recived_cnt, acksize);
                dec(RxBufSize, acksize);
                AppendTextFileForbackupFail_Updation(s + ' Time : ' + FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ',
                  Now), 'C:\NMRH\WAS\ACK_Recived.txt');
              end;
            end;
          except
            on e: Exception do
            begin
              AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
                'Module : 4090 Server Execute ' + ' Time :' +
                FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
                'C:\NMRH\WAS\Exceptions.txt');
            end;
          end;
        end;
      5001: // to recive data from nmdl
        begin
          try
            begin
              AContext.Connection.IOHandler.ReadBytes(RxBufStr,RxBufSize, false);
              CriticalSection.Enter;
              No_ofpacket := RxBufSize div 58;
              if No_ofpacket >= 1 then
              begin
                X := 0;
                for i := 0 to No_ofpacket do
                begin
                  if(RxBufStr[X]=123) and (RxBufStr[X+57]=125) then
                  begin
                    move(RxBufStr[X], TempRecvBuf_train[point_idxT], 58);
                    inc(point_idxT, 58);
                    X := X + 58;
                  end
                  else
                  begin
                    while(x+57)<RxBufSize do
                    begin
                      if (RxBufStr[X]=123) and (RxBufStr[X+57]=125) then
                        break
                      else
                        X := X+1;
                    end;
                  end;
                  // move(RxBufStr[0], TempRecvBuf_train[point_idxT], RxBufSize);
                  // inc(point_idxT, RxBufSize);
                end;
              end;
              CriticalSection.Leave;
              s := TEncoding.UTF8.GetString(RxBufStr);
              AppendTextFileForbackupFail_Updation(s + 'Module : 5001 Server Execute ' + ' Time : ' +FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
                'C:\NMRH\WAS\Nmdl_Recived.txt');
            end;
          except
            on e: Exception do
            begin
              AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
                'Module : 5001 Server Execute ' + ' Time :' +
                FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
                'C:\NMRH\WAS\Exceptions.txt');
            end;
          end;
        end;
    end;
  End
  else
  begin
    IndySleep(10);
  end;
end;

procedure update_active_workers(p_route, n_route, index: Word);
var
  i, j, k: Word;
  len: Word;
begin
  try
    if (p_route <> 0) then
    begin
      len := length(active_workers[p_route]);
      for i := 0 to len do
      begin
        if (active_workers[p_route][i] = index) then
        begin
          for j := i to len - 1 do
          begin
            active_workers[p_route][j] := active_workers[p_route][j + 1];
          end;
          SetLength(active_workers[p_route], len - 1);
          break
        end;
      end;
    end;
    if (n_route <> 0) then
    begin
      len := length(active_workers[n_route]);
      SetLength(active_workers[n_route], len + 1);
      active_workers[n_route][len] := index;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        'Module : active workers function' + 'Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
end;

procedure update_worker_buf(data: String; ipadress: string; portno: Word);
var
  JSonObject_W: TJSonObject;
  JSonValue_W: TJSonValue;
  Wk_Data: workerdata;
  Ser_Context, client_context: TIdContext;
  i, count: Word;
  Cli_List: TList;
begin
  try
    i := 0;
    JSonObject_W := TJSonObject.Create;
    JSonValue_W := JSonObject_W.ParseJSONValue(data);
    Wk_Data.p_lat := strtofloat(((JSonValue_W) as TJSonObject).Get('Longitude')
      .JSonValue.Value);
    Wk_Data.p_lon := strtofloat(((JSonValue_W) as TJSonObject).Get('Latitude')
      .JSonValue.Value);
    Wk_Data.IMEI_no := ((JSonValue_W) as TJSonObject).Get('IMEI')
      .JSonValue.Value;
    JSonObject_W.Free;
    try
      Cli_List := MapDisplay.IdTCPServer1.Contexts.LockList;
      for count := 0 to Cli_List.count - 1 do
      begin
        if (Cli_List.Items[count] <> nil) then
        begin
          Ser_Context := TIdContext(Cli_List.Items[count]);
          if Ser_Context.Binding.PeerIP = ipadress then
          begin
            if Ser_Context.Binding.PeerPort = portno then
            begin
              client_context := Ser_Context;
              break;
            end
          end;
        end;
      end;
    finally
      MapDisplay.IdTCPServer1.Contexts.UnlockList;
    end;
    for i := 1 to length(worker_buf) - 1 do
    begin
      if Wk_Data.IMEI_no = worker_buf[i].IMEI_no then
      begin
        worker_buf[i].p_lat := Wk_Data.p_lat;
        worker_buf[i].p_lon := Wk_Data.p_lon;
        if (worker_buf[i].context <> nil) then
        begin
          if (worker_buf[i].context <> client_context) then
          begin
            Cli_List := MapDisplay.IdTCPServer1.Contexts.LockList;
            worker_buf[i].context.Connection.IOHandler.WriteBufferClear;
            worker_buf[i].context.Connection.IOHandler.InputBuffer.Clear;
            worker_buf[i].context.Connection.Disconnect;
            MapDisplay.IdTCPServer1.Contexts.UnlockList;
          end;
        end;
        worker_buf[i].context := client_context;
        break;
      end;
    end;
    if (i = length(worker_buf)) then
    begin
      SetLength(worker_buf, length(worker_buf) + 1);
      worker_buf[i].p_lat := Wk_Data.p_lat;
      worker_buf[i].p_lon := Wk_Data.p_lon;
      worker_buf[i].IMEI_no := Wk_Data.IMEI_no;
      worker_buf[i].context := client_context;
      worker_buf[i].Route_no := 0;
      worker_buf[i].attachment := false;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        'Module : Update worker timer' + 'Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
end;

procedure Disconnectallclients;
var
  iA: Integer;
  context: TIdContext;
  samList: TList;
begin
  try
    if (MapDisplay.IdTCPServer1.Active) then
    begin
      samList := MapDisplay.IdTCPServer1.Contexts.LockList;
      for iA := samList.count - 1 downto 0 do
      begin
        context := TIdContext(samList.Items[iA]);
        if context = nil then
          continue;
        context.Connection.IOHandler.WriteBufferClear;
        context.Connection.IOHandler.InputBuffer.Clear;
        context.Connection.IOHandler.Close;
        context.Connection.Disconnect;
      end;
      MapDisplay.IdTCPServer1.Contexts.UnlockList;
      MapDisplay.IdTCPServer1.Active := false;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Disconnectallclients ' + 'Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
end;

procedure update_Notification_buf(train_data: String);
var
  JSonObject_T: TJSonObject;
  JSonValue_T: TJSonValue;
  Tr_data: Train_Record;
  i, j, k: Word;
begin
  try
    j := 0;
    JSonObject_T := TJSonObject.Create;
    JSonValue_T := JSonObject_T.ParseJSONValue(train_data);
    AppendTextFileForbackupFail_Updation(train_data + ' '+ FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
      'C:\NMRH\WAS\Nmdl_Update_Notify.txt');
    Tr_data.Line_no := strtoint(((JSonValue_T) as TJSonObject).Get('L')
      .JSonValue.Value);
    Tr_data.station_id := strtoint(((JSonValue_T) as TJSonObject).Get('S')
      .JSonValue.Value);
    Tr_data.Route_no := strtoint(((JSonValue_T) as TJSonObject).Get('R')
      .JSonValue.Value);
    Tr_data.time := ((JSonValue_T) as TJSonObject).Get('T').JSonValue.Value;
    if (((JSonValue_T) as TJSonObject).Get('M').JSonValue.Value = 'DEP') then
    begin
      Tr_data.train_move := true;
    end
    else
    begin
      Tr_data.train_move := false;
    end;
    JSonObject_T.Free;
    if (Tr_data.train_move) then
    begin
      // if((MinutesBetween(TimeOf(now),StrToTime(copy(Tr_data.time,1, 8))))<=6) then
      begin
        if (length(active_workers[Tr_data.Route_no]) <> 0) then
        begin
          i := length(notification_buf);
          while j < length(active_workers[Tr_data.Route_no]) do
          begin
            if worker_buf[active_workers[Tr_data.Route_no][j]].context <> nil
            then
            begin
              SetLength(notification_buf, length(notification_buf) + 1);
              notification_buf[i].station_id := Tr_data.station_id;
              notification_buf[i].Line_no := Tr_data.Line_no;
              notification_buf[i].start_time := Tr_data.time;
              notification_buf[i].IMEI_no :=
                worker_buf[active_workers[Tr_data.Route_no][j]].IMEI_no;
              notification_buf[i].context :=
                worker_buf[active_workers[Tr_data.Route_no][j]].context;
              inc(i, 1);
            end;
            inc(j, 1);
          end;
        end;
      end;
      // else
      // begin
      // AppendTextFileForbackupFail_Updation(train_data +' '+ datetostr(Now) + ' ' + FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ',Now),
      // 'C:\NMRH\WAS\TimeDelay.txt');
      // end;
    end
    else
    begin
      if (length(notification_buf) <> 0) and
        (length(active_workers[Tr_data.Route_no]) <> 0) then
      begin
        for j := 0 to length(active_workers[Tr_data.Route_no]) - 1 do
        begin
          for i := 0 to length(notification_buf) - 1 do
          begin
            if (notification_buf[i].IMEI_no = worker_buf
              [active_workers[Tr_data.Route_no][j]].IMEI_no) then
            begin
              if (notification_buf[i].Line_no = Tr_data.Line_no) then
              begin
                for k := i to length(notification_buf) - 1 do
                begin
                  notification_buf[k] := notification_buf[k + 1];
                end;
                SetLength(notification_buf, length(notification_buf) - 1);
              end;
              break
            end;
          end;
        end;
      end;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        'Module: Update Notification buf Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
end;

procedure TMapDisplay.RemovedClick(Sender: TObject);
var
  detached_list: array of string;
begin
  Application.CreateForm(TDetached, Detached);
  Detached.Show();
end;

procedure TMapDisplay.Refresh_displayTimer(Sender: TObject);
var
  i: Word;
  X, Y: double;
  pre: Word;
  myseries1: TLineSeries;
begin
  Refresh_display.Enabled := false;
  try
    Series2.Clear;
    for i := 1 to length(worker_buf) - 1 do
    begin
      Series2.AddXY(worker_buf[i].p_lat, worker_buf[i].p_lon);
      if (worker_buf[i].attachment = true) then
      begin
        update_line(worker_buf[i].seriesno, i);
        Series2.Pointer[i - 1].Size := 4;
        X := worker_buf[i].p_lat;
        Y := worker_buf[i].p_lon;
        if (X > xmax) or (X < Xmin) or (Y < Ymin) or (Y > ymax) then
        begin
          // pre:= worker_buf[i].Route_no;
          // worker_buf[i].attachment:=false;
          // worker_buf[i].Route_no:=0;
          // update_active_workers(pre,0,i);
          // MapDisplay.update_line(worker_buf[i].Route_no,i);
          // AppendTextFileForbackupFail_Updation('Person : ' + worker_buf[i].IMEI_no +
          // ' RouteNo : ' + inttostr(pre) + ' Removed : out of x-('
          // +floattostr(xmin)+','+floattostr(xmax)+') y-('
          // +floattostr(ymin)+','+floattostr(ymax)+') '+' Time :'
          // +datetostr(Now)+' '+TimeToStr(Now), 'C:\NMRH\WAS\RemovePersons.txt');
        end
      end
      else
      begin
        if flag = true then
        begin
          if i = seriesindex2 + 1 then
            continue;
          Series2.Pointer[i - 1].Color := TAlphaColorRec.Lightcoral;
          Chart1.Legend.Item[i - 1].Text := inttostr(i) + ' Not attached';
          Series2.Pointer[i - 1].Size := 3;
        end
        else if (worker_buf[i].attachment = false) then
        begin
          Series2.Pointer[i - 1].Color := TAlphaColorRec.Lightcoral;
          Chart1.Legend.Item[i - 1].Text := inttostr(i) + ' Not attached';
          Series2.Pointer[i - 1].Size := 3;
        end;
      end;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Refresh_display ' + ' Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
  Refresh_display.Enabled := true;
end;

procedure TMapDisplay.Worker_locTimer(Sender: TObject);
var
  i: Byte;
  wk_str: string;
  wk_port: Word;
  wk_bytes, wk_ipBy, wk_PortBy: TBytes;
  wk_ipStr: string;
begin
  try
    Worker_loc.Enabled := false;
    // if (point_idx >= 93) then    //point_idx%93=0;
    if ((point_idx mod 93) = 0) then // worlocsize(76)+port(2)+host(15)=93
    begin
      SetLength(wk_bytes, workerlocsize);
      SetLength(wk_ipBy, host_len);
      SetLength(wk_PortBy, port_len);
      while point_idx <> 0 do
      begin
        move(TempRecvBuf_loc[0], wk_bytes[0], workerlocsize);
        // AppendTextFileForbackupFail_Updation
        // (TEncoding.UTF8.GetString(TempRecvBuf_loc) + TEncoding.UTF8.GetString
        // (wk_bytes), 'C:\NMRH\WAS\TempRecvBuf_loc.txt');
        move(TempRecvBuf_loc[workerlocsize], wk_ipBy[0], host_len);
        move(TempRecvBuf_loc[91], wk_PortBy[0], port_len);
        move(TempRecvBuf_loc[93], TempRecvBuf_loc, max_ippacket_size);
        dec(point_idx, 93);
        i := length(wk_ipBy) - 1;
        while (wk_ipBy[i] = 0) do
        begin
          dec(i, 1);
        end;
        wk_str := TEncoding.UTF8.GetString(wk_bytes);
        wk_ipStr := TEncoding.UTF8.GetString(wk_ipBy, 0, i + 1);
        wordrec(wk_port).lo := wk_PortBy[0];
        wordrec(wk_port).hi := wk_PortBy[1];
        update_worker_buf(wk_str, wk_ipStr, wk_port);
      end;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Worker_loc ' + 'Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
  Worker_loc.Enabled := true;
end;

procedure TMapDisplay.Update_notificationsTimer(Sender: TObject);
var
  train_Bytes: TBytes;
  train_Str: String;
begin
  try
    Update_notifications.Enabled := false;
    if (point_idxT >= tr_recpacket_size) then // tr_recpacket_size :58
    begin
      SetLength(train_Bytes, tr_recpacket_size);
      while point_idxT <> 0 do
      begin
        move(TempRecvBuf_train[0], train_Bytes[0], tr_recpacket_size);
        move(TempRecvBuf_train[tr_recpacket_size], TempRecvBuf_train,
          max_ippacket_size);
        dec(point_idxT, tr_recpacket_size);
        train_Str := TEncoding.UTF8.GetString(train_Bytes, 0,
          tr_recpacket_size);
        update_Notification_buf(train_Str);
      end;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Update_notifications ' + 'Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
  Update_notifications.Enabled := true;
end;

procedure TMapDisplay.Ack_WkTimer(Sender: TObject);
var
  ACK_Bytes: TBytes;
  ACK_Str, Res_time, imei: String;
  i, row, line: Word;
  del_log: string;
  JSonObject_Ack: TJSonObject;
  JSonValue_Ack: TJSonValue;
begin
  try
    Ack_Wk.Enabled := false;
    if (point_idxA >= acksize) then
    begin
      SetLength(ACK_Bytes, acksize);
      while (point_idxA <> 0) do
      begin
        move(TempRecvBuf_ACK[0], ACK_Bytes[0], acksize);
        move(TempRecvBuf_ACK[acksize], TempRecvBuf_ACK, max_ippacket_size);
        // max_ippacket_size : 65535
        dec(point_idxA, acksize);
        ACK_Str := TEncoding.UTF8.GetString(ACK_Bytes);
        JSonObject_Ack := TJSonObject.Create;
        JSonValue_Ack := JSonObject_Ack.ParseJSONValue(ACK_Str);
        Res_time := ((JSonValue_Ack) as TJSonObject).Get('R_time')
          .JSonValue.Value;
        line := strtoint(((JSonValue_Ack) as TJSonObject).Get('L')
          .JSonValue.Value);
        imei := ((JSonValue_Ack) as TJSonObject).Get('IMEI').JSonValue.Value;
        if (length(notification_buf) <> 0) then
        begin
          for i := 0 to length(notification_buf) - 1 do
          begin
            if (notification_buf[i].IMEI_no = imei) then
            begin
              if (notification_buf[i].Line_no = line) then
              begin
                if (notification_buf[i].context <> nil) then
                begin
                  notification_buf[i].status := true;
                  notification_buf[i].response_time := Res_time;
                  del_log := notification_buf[i].response_time + ' ' +
                    inttostr(notification_buf[i].station_id) + ' ' +
                    inttostr(notification_buf[i].Line_no) + ' ' +
                    notification_buf[i].start_time + ' ' + notification_buf
                    [i].IMEI_no;
                  AppendTextFileForbackupFail_Updation
                    ('Delete: ' + del_log + 'Module : ack_wk timer ' + ' Time :'
                    + FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
                    'C:\NMRH\WAS\Notification.txt');
                  for row := i to length(notification_buf) - 1 do
                  begin
                    notification_buf[row] := notification_buf[row + 1];
                  end;
                  SetLength(notification_buf, length(notification_buf) - 1);
                  break;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Ack_Wk ' + 'Time :' +
        FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ', Now),
        'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
  Ack_Wk.Enabled := true;
end;

procedure TMapDisplay.Send_NotifyTimer(Sender: TObject);
var
  Ser_Context: TIdContext;
  Cli_List: TList;
  row, count: Word;
  json_notify: TJSonObject;
  i: Integer;
  st_name: string;
begin
  try
    Send_Notify.Enabled := false;
    // AppendTextFileForbackupFail_Updation(' Module : Send_Notify '
    // + 'Time :' + FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ',Now)  ,'C:\NMRH\WAS\sample.txt');
    if (length(notification_buf) <> 0) then
    begin
      for row := 0 to length(notification_buf) - 1 do
      begin
        if (not notification_buf[row].status) then
        begin
          if notification_buf[row].context <> nil then
          begin
            if (notification_buf[row].count = 0) or
              (notification_buf[row].count > 15) then
            begin
              try
                json_notify := TJSonObject.Create;
                for i := 0 to length(st_buf) - 1 do
                begin
                  if (st_buf[i].station_id = notification_buf[row].station_id)
                  then
                    st_name := st_buf[i].Station_name;
                end;
                json_notify.AddPair(TJsonPair.Create('S', st_name));
                json_notify.AddPair(TJsonPair.Create('L',
                  inttostr(notification_buf[row].Line_no)));
                json_notify.AddPair(TJsonPair.Create('T',
                  (notification_buf[row].start_time)));
                notification_buf[row].count := 1;
                MapDisplay.IdTCPServer1.Contexts.LockList;
                notification_buf[row].context.Connection.IOHandler.
                  Write(json_notify.ToString);
                AppendTextFileForbackupFail_Updation(json_notify.ToString +
                  ' Module : Send_Notify ' + 'Time :' + datetostr(Now) + ' ' +
                  TimeToStr(Now), 'C:\NMRH\WAS\notificationsend.txt');
                MapDisplay.IdTCPServer1.Contexts.UnlockList;
              except
                on e: Exception do
                begin
                  AppendTextFileForbackupFail_Updation('Exception: ' + e.Message
                    + ' Module : Send_Notify ' + 'Time :' + datetostr(Now) + ' '
                    + TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
                  Send_Notify.Enabled := true;
                end
              end;
            end
            else
            begin
              notification_buf[row].count := notification_buf[row].count + 1
            end;
          end;
        end;
      end;
    end;
  except
    on e: Exception do
    begin
      AppendTextFileForbackupFail_Updation('Exception: ' + e.Message +
        ' Module : Send_Notify_final ' + 'Time :' + datetostr(Now) + ' ' +
        TimeToStr(Now), 'C:\NMRH\WAS\Exceptions.txt');
    end;
  end;
  Send_Notify.Enabled := true;
end;

end.
