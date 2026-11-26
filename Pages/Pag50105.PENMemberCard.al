page 50105 "PEN Member Card"
{
    ApplicationArea = All;
    Caption = 'PEN Member';
    PageType = Card;
    SourceTable = "PEN Member";

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
                field("First Name"; Rec."First Name")
                {
                    ToolTip = 'Specifies the value of the First Name field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("Last Name"; Rec."Last Name")
                {
                    ToolTip = 'Specifies the value of the Last Name field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("National ID No."; Rec."National ID No.")
                {
                    ToolTip = 'Specifies the value of the National ID No. field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("Date of Birth"; Rec."Date of Birth")
                {
                    ToolTip = 'Specifies the value of the Date of Birth field.', Comment = '%';
                }
                field("Employer No."; Rec."Employer No.")
                {
                    ToolTip = 'Specifies the value of the Employer No. field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("Scheme Code"; Rec."Scheme Code")
                {
                    ToolTip = 'Specifies the value of the Scheme Code field.', Comment = '%';
                }
                field("Date Joined"; Rec."Date Joined")
                {
                    ToolTip = 'Specifies the value of the Date Joined field.', Comment = '%';
                    ShowMandatory = true;
                }
                field("Pensionable Salary"; Rec."Pensionable Salary")
                {
                    ToolTip = 'Specifies the value of the Pensionable Salary field.', Comment = '%';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the value of the Status field.', Comment = '%';
                }
                field(Balance; Rec.Balance)
                {
                    ToolTip = 'Specifies the value of the Balance field.', Comment = '%';
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
        PENSetup.TestField("Member Nos.");
        NoFieldVisible := NoSeries.IsManual(PENSetup."Member Nos.");
    end;
}
