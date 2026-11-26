page 50107 "PEN Contribution Queues"
{
    ApplicationArea = All;
    Caption = 'PEN Contribution Queues';
    PageType = Worksheet;
    SourceTable = "PEN Contribution Queue";

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                field("Batch No."; Rec."Batch No.")
                {
                    ToolTip = 'Specifies the value of the Batch No. field.', Comment = '%';
                }
            }
            repeater(Lines)
            {
                ShowCaption = false;

                field("Member No."; Rec."Member No.")
                {
                    ToolTip = 'Specifies the value of the Member No. field.', Comment = '%';
                }
                field("Employee Amount"; Rec."Employee Amount")
                {
                    ToolTip = 'Specifies the value of the Employee Amount field.', Comment = '%';
                }
                field("Employer Amount"; Rec."Employer Amount")
                {
                    ToolTip = 'Specifies the value of the Employer Amount field.', Comment = '%';
                }
                field(Period; Rec.Period)
                {
                    ToolTip = 'Specifies the value of the Period field.', Comment = '%';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.', Comment = '%';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ToolTip = 'Specifies the value of the Retry Count field.', Comment = '%';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ToolTip = 'Specifies the value of the Last Error field.', Comment = '%';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Reprocess)
            {
                Caption = 'Reprocess';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    Processor: Codeunit "PEN Process Contributions";
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    Processor.Reprocess(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
