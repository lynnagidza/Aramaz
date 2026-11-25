page 50102 "PEN Employer List"
{
    ApplicationArea = All;
    Caption = 'PEN Employers';
    PageType = List;
    SourceTable = "PEN Employer";
    Editable = false;
    CardPageId = "PEN Employer Card";

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
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the value of the Name field.', Comment = '%';
                }
                field("Scheme Code"; Rec."Scheme Code")
                {
                    ToolTip = 'Specifies the value of the Scheme Code field.', Comment = '%';
                }
                field("KRA PIN"; Rec."KRA PIN")
                {
                    ToolTip = 'Specifies the value of the KRA PIN field.', Comment = '%';
                }
                field(Email; Rec.Email)
                {
                    ToolTip = 'Specifies the value of the Email field.', Comment = '%';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.', Comment = '%';
                }
                field("Member Count"; Rec."Member Count")
                {
                    ToolTip = 'Specifies the value of the Member Count field.', Comment = '%';
                }
            }
        }
    }
}
