unit Detachedpersons;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TDetached = class(TForm)
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Detached: TDetached;

implementation

{$R *.fmx}

procedure TDetached.FormClose(Sender: TObject; var Action: TCloseAction);
begin
Action := TCloseAction.caFree;
end;

procedure TDetached.FormCreate(Sender: TObject);
var
  i,ct: word;
  F: TextFile;
  N: Integer;
  fileName: string;
  text:string;
begin
fileName := 'C:\NMRH\WAS\RemovePersons.txt';
if FileExists(fileName) then
begin
  AssignFile(F, fileName);
  Reset(F);
  while not Eof(F) do
  begin
    ReadLn(F, text);
    //ShowMessage(text);
    Label1.Text:= Label1.Text+text+#13;
  end;
  CloseFile(F);
end;
end;

procedure TDetached.FormDeactivate(Sender: TObject);
begin
Detached.Close;
end;

end.
