table 50102 "PEN Employer"
{
    Caption = 'PEN Employer';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            trigger OnValidate()
            begin
                if not ("No." = xRec."No.") then begin
                    PENSetup.Get();
                    NoSeries.TestManual(PENSetup."Employer Nos.");
                end;
                if "No." = '' then
                    InitRec();
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; "Scheme Code"; Code[20])
        {
            Caption = 'Scheme Code';
            NotBlank = true;
            TableRelation = "PEN Scheme";
        }
        field(4; "KRA PIN"; Code[20])
        {
            Caption = 'KRA PIN';
            NotBlank = true;
            trigger OnValidate()
            var
                PENEmployer: Record "PEN Employer";
            begin
                // Format A000000000Z
                ValidateKRAPINFormat();
                // should be unique
                PENEmployer.SetRange("KRA PIN", "KRA PIN");
                PENEmployer.SetFilter("No.", '<>%1', "No.");
                if PENEmployer.FindFirst() then
                    Error('An employer with the KRA PIN %1 already exists.', PENEmployer."KRA PIN");
            end;
        }
        field(5; Email; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("Email");
            end;
        }
        field(6; Status; Enum "PEN Employer Status")
        {
            Caption = 'Status';
        }
        field(7; "Member Count"; Integer)
        {
            Caption = 'Member Count';
            FieldClass = FlowField;
            CalcFormula = count("PEN Member" where(Status = filter(Active), "Employer No." = field("No.")));
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        InitRec();
    end;

    var
        PENSetup: Record "PEN Pension Setup";
        NoSeries: Codeunit "No. Series";

    local procedure InitRec()
    begin
        if not PENSetup.Get() then
            Error('The PEN Pension Setup has not been configured.\Configure it first before continuing.');
        PENSetup.TestField("Employer Nos.");
        if "No." = '' then
            "No." := NoSeries.GetNextNo(PENSetup."Employer Nos.");
    end;

    local procedure ValidateKRAPINFormat()
    var
        i: Integer;
        FirstChar, LastChar : Text;
        UppercaseString: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    begin
        // Length check
        if StrLen("KRA PIN") <> 11 then
            Error('KRA PIN must contain exactly 11 characters.');

        // First & last character check
        FirstChar := CopyStr("KRA PIN", 1, 1);
        LastChar := CopyStr("KRA PIN", 11, 1);
        if (StrPos(UppercaseString, FirstChar) = 0) or (StrPos(UppercaseString, LastChar) = 0) then
            Error('KRA PIN must start and end with a letter.');

        // In-between number characters check
        for i := 2 to 10 do
            if StrPos('0123456789', CopyStr("KRA PIN", i, 1)) = 0 then
                Error('KRA PIN characters 2 to 10 must be digits.');
    end;

    procedure AssistEdit(xEmployer: Record "PEN Employer") Result: Boolean
    var
        PENEmployer: Record "PEN Employer";
    begin
        PENEmployer.Copy(Rec);
        PENSetup.Get();
        PENSetup.TestField("Employer Nos.");
        "No." := NoSeries.GetNextNo(PENSetup."Employer Nos.");
        Rec := PENEmployer;
        exit(true);
    end;
}
