Como gerar o instalador do prototipo
====================================

1) Instale o Inno Setup 6 (se ainda nao tiver).
2) Abra o arquivo:
   Instalador\AulaFast_Prototipo.iss
3) Clique em "Compile".
4) Ao final sera gerado:
   Instalador\Setup_AulaFast_Prototipo.exe

O instalador copia:
- AulaFast.exe
- RelClientes.fr3
- AssinarPDF\BIN\JSignPdfC.exe
- AssinarPDF\BIN\app\*
- AssinarPDF\BIN\runtime\*
- cria AssinarPDF\PDFAssinados

Observacao:
- O runtime do JSignPdf e grande e fica fora do Git, mas deve existir localmente
  para o instalador incluir os arquivos.
