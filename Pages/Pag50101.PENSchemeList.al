page 50101 "PEN Scheme List"
{
    ApplicationArea = All;
    Caption = 'PEN Schemes';
    PageType = List;
    SourceTable = "PEN Scheme";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the value of the Code field.', Comment = '%';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.', Comment = '%';
                }
                field("Scheme Type"; Rec."Scheme Type")
                {
                    ToolTip = 'Specifies the value of the Scheme Type field.', Comment = '%';
                }
                field("Employer Cap %"; Rec."Employer Cap %")
                {
                    ToolTip = 'Specifies the value of the Employer Cap % field.', Comment = '%';
                }
                field("Contribution Receivable Acc."; Rec."Contribution Receivable Acc.")
                {
                    ToolTip = 'Specifies the value of the Contribution Receivable Acc. field.', Comment = '%';
                }
                field("Member Liability Acc."; Rec."Member Liability Acc.")
                {
                    ToolTip = 'Specifies the value of the Member Liability Acc. field.', Comment = '%';
                }
                field("Penalty Income Acc."; Rec."Penalty Income Acc.")
                {
                    ToolTip = 'Specifies the value of the Penalty Income Acc. field.', Comment = '%';
                }
                field(Blocked; Rec.Blocked)
                {
                    ToolTip = 'Specifies the value of the Blocked field.', Comment = '%';
                }
            }
        }
    }
}
