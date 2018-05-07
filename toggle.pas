unit toggle;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  Tclick_tag = class(TForm)
    change: TButton;
    remove: TButton;
    Label1: TLabel;
    procedure removeClick(Sender: TObject);
    procedure changeClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;
Procedure AppendTextFileForbackupFail_Updation(s, FileName: String);
var
  click_tag: Tclick_tag;


implementation

{$R *.fmx}
uses MainMap;
procedure Tclick_tag.changeClick(Sender: TObject);
begin
click_tag.Close;
flag:=true;
showmessage('person select route to attach');
end;


procedure Tclick_tag.removeClick(Sender: TObject);
var
previous_route:word;
begin
  click_tag.Close;
  ShowMessage('person '+inttostr(seriesindex2+1)+'is removed from route'+inttostr(worker_buf[seriesindex2 + 1].Route_no));
  previous_route:=worker_buf[seriesindex2 + 1].Route_no;
  worker_buf[seriesindex2 + 1].Route_no := 0;
  worker_buf[seriesindex2 + 1].attachment := false;
  MapDisplay.update_line(worker_buf[seriesindex2 + 1].Route_no,seriesindex2+1);
  update_active_workers(previous_route,0,seriesindex2 + 1 );
  AppendTextFileForbackupFail_Updation('Person : ' + worker_buf[seriesindex2 + 1].IMEI_no  + ' RouteNo : ' + inttostr(previous_route) + ' Removed : Manually Detached; Time : '+FormatDateTime('DD/MM/YYYY HH:MM:SS.ZZZ',Now),'C:\NMRH\WAS\RemovePersons.txt');
end;

Procedure AppendTextFileForbackupFail_Updation(s, FileName: String);
Var
  T: textfile;
  FileWithoutExt: String;
  iFileHandle, SizeOfFile: Integer;
Begin
  try
    If IOResult <> 0 Then
      ;
    AssignFile(T, FileName);
{$I-} ReSet(T); {$I+}
    If IOResult <> 0 Then
    begin
{$I-} ReWrite(T){$I+}
    end
    Else
    begin
{$I-} Append(T){$I+}
    end;
    if IOResult = 0 then
    begin
{$I-} Writeln(T, s); {$I+}
      CloseFile(T);
      // added to create new file when the files size exceeds to 5MB

    end;
    If IOResult <> 0 Then
      ;
  Except
    On E: exception do

    End;
  end;
end.

