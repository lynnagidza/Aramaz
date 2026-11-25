page 50100 "PEN Pension Setup"
{
    ApplicationArea = All;
    Caption = 'PEN Pension Setup';
    PageType = Card;
    SourceTable = "PEN Pension Setup";
    
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                
                field("Remittance Due Day "; Rec."Remittance Due Day ")
                {
                    ToolTip = 'Specifies the value of the Remittance Due Day field.', Comment = '%';
                }
                field("Late Penalty % "; Rec."Late Penalty % ")
                {
                    ToolTip = 'Specifies the value of the Late Penalty % field.', Comment = '%';
                }
                field("Queue Batch Size "; Rec."Queue Batch Size ")
                {
                    ToolTip = 'Specifies the value of the Queue Batch Size field.', Comment = '%';
                }
                field("Max Retry Attempts "; Rec."Max Retry Attempts ")
                {
                    ToolTip = 'Specifies the value of the Max Retry Attempts field.', Comment = '%';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                
                field("Member Nos."; Rec."Member Nos.")
                {
                    ToolTip = 'Specifies the value of the Member Nos. field.', Comment = '%';
                }
                field("Employer Nos."; Rec."Employer Nos.")
                {
                    ToolTip = 'Specifies the value of the Employer Nos. field.', Comment = '%';
                }
                field("Contribution Batch Nos."; Rec."Contribution Batch Nos.")
                {
                    ToolTip = 'Specifies the value of the Contribution Batch Nos. field.', Comment = '%';
                }
            }
        }
    }
}
