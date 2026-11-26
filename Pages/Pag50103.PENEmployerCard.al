page 50103 "PEN Employer Card"
{
    ApplicationArea = All;
    Caption = 'PEN Employer';
    PageType = Card;
    SourceTable = "PEN Employer";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the value of the No. field.', Comment = '%';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit(xRec);
                    end;
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the value of the Name field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("Scheme Code"; Rec."Scheme Code")
                {
                    ToolTip = 'Specifies the value of the Scheme Code field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("KRA PIN"; Rec."KRA PIN")
                {
                    ToolTip = 'Specifies the value of the KRA PIN field.', Comment = '%';
                    ShowMandatory = true;
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
    trigger OnOpenPage()
    begin
        SetNoFieldVisible();
    end;

    var
        NoFieldVisible: Boolean;

    local procedure SetNoFieldVisible()
    var
        NoSeries: Codeunit "No. Series";
        PENSetup: Record "PEN Pension Setup";
    begin
        PENSetup.Get();
        PENSetup.TestField("Employer Nos.");
        NoFieldVisible := NoSeries.IsManual(PENSetup."Employer Nos.");
    end;
}
