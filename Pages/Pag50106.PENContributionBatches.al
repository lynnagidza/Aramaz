page 50106 "PEN Contribution Batches"
{
    ApplicationArea = All;
    Caption = 'PEN Contribution Batches';
    PageType = List;
    SourceTable = "PEN Contribution Batch";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.', Comment = '%';
                }
                field(Period; Rec.Period)
                {
                    ToolTip = 'Specifies the value of the Period field.', Comment = '%';
                }
                field("Received Date"; Rec."Received Date")
                {
                    ToolTip = 'Specifies the value of the Received Date field.', Comment = '%';
                }
                field("Control Total"; Rec."Control Total")
                {
                    ToolTip = 'Specifies the value of the Control Total field.', Comment = '%';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Import Contributions")
            {
                Caption = 'Import Contributions';
                Image = Import;
                ToolTip = 'Upload contributions (supported files: json, csv)';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                trigger OnAction()
                var
                    FileName, FileExt : Text;
                    FileMgmt: Codeunit "File Management";
                    TempBlob: Codeunit "Temp Blob";
                    UploadTxt: Label 'Upload';
                    AcceptedFiles: Label 'Supported files (*.csv;*.json)|*.csv;*.json';
                    FileNameErr: Label 'Please select a valid CSV or JSON file.';
                    ImportContribution: Codeunit "PEN Import Contribution";
                    ImportedInStream: InStream;
                    PENSetup: Record "PEN Pension Setup";
                begin
                    FileName := FileMgmt.BLOBImportWithFilter(TempBlob, UploadTxt, FileName, AcceptedFiles, AcceptedFiles);
                    FileExt := FileMgmt.GetExtension(FileName);
                    if (FileName = '') or (not TempBlob.HasValue()) or not (FileExt in ['csv', 'json']) then begin
                        FileName := '';
                        Error(FileNameErr);
                    end else begin
                        PENSetup.Get();
                        PENSetup.TestField("Contribution Batch Nos.");
                        TempBlob.CreateInStream(ImportedInStream);
                        case
                   FileExt of
                            'csv':
                                ImportContribution.ImportCSV(ImportedInStream);
                            'json':
                                ImportContribution.ImportJSON(ImportedInStream);
                        end;
                    end;
                end;
            }
        }
    }
}
