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
                begin
                    // TODO: limit files to selected extensions, route to the necessary objects/procedures to read this data and insert them accordingly
                end;
            }
        }
    }
}
