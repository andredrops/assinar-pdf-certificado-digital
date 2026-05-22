program AulaFast;

uses
  Vcl.Forms,
  uAulaFast in 'uAulaFast.pas' {Form1},
  uAssinarPDF in 'AssinarPDF\uAssinarPDF.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
