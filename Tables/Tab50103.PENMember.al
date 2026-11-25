table 50103 "PEN Member"
{
    Caption = 'PEN Member';
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
                    NoSeries.TestManual(PENSetup."Member Nos.");
                end;
                if "No." = '' then
                    InitRec();
            end;
        }
        field(2; "First Name"; Text[50])
        {
            Caption = 'First Name';
            NotBlank = true;
        }
        field(3; "Last Name"; Text[50])
        {
            Caption = 'Last Name';
            NotBlank = true;
        }
        field(4; "National ID No."; Code[20])
        {
            Caption = 'National ID No.';
            NotBlank = true;
            trigger OnValidate()
            var
                PENMember: Record "PEN Member";
            begin
                PENMember.SetRange("National ID No.", "National ID No.");
                PENMember.SetFilter("No.", '<>%1', "No.");
                if PENMember.FindFirst() then
                    Error('A member with the National ID No. %1 already exists.');
            end;
        }
        field(5; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
        }
        field(6; "Employer No."; Code[20])
        {
            Caption = 'Employer No.';
            NotBlank = true;
            TableRelation = "PEN Employer";
            trigger OnValidate()
            var
                PENEmployer: Record "PEN Employer";
            begin
                if PENEmployer.Get("Employer No.") then begin
                    CheckMemberPrerequisites();
                    "Scheme Code" := PENEmployer."Scheme Code"
                end else
                    "Scheme Code" := '';
            end;
        }
        field(7; "Scheme Code"; Code[20])
        {
            Caption = 'Scheme Code';
            TableRelation = "PEN Scheme";
            Editable = false;
        }
        field(8; "Date Joined"; Date)
        {
            Caption = 'Date Joined';
            NotBlank = true;
            trigger OnValidate()
            begin
                ValidateAge();
            end;
        }
        field(9; "Pensionable Salary"; Decimal)
        {
            Caption = 'Pensionable Salary';
            MinValue = 1;
        }
        field(10; Status; Enum "PEN Member Status")
        {
            Caption = 'Status ';
        }
        field(11; Balance; Decimal)
        {
            Caption = 'Balance';
            FieldClass = FlowField;
            CalcFormula = sum("PEN Member Ledger Entry".Amount);
            Editable = false;
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
        PENSetup.TestField("Member Nos.");
        if "No." = '' then
            "No." := NoSeries.GetNextNo(PENSetup."Member Nos.");
    end;

    local procedure CheckMemberPrerequisites()
    var
        PENEmployer: Record "PEN Employer";
        PENScheme: Record "PEN Scheme";
    begin
        PENEmployer.Get("Employer No.");
        if PENEmployer.Status = PENEmployer.Status::Suspended then
            Error('%1 is suspended. A member cannot be created against a suspended employer.', PENEmployer.Name);

        PENScheme.Get(PENEmployer."Scheme Code");
        if PENScheme.Blocked then
            Error('The selected employer %1''s scheme %2 is blocked. A member cannot be created against a blocked scheme.', PENEmployer.Name, PENEmployer."Scheme Code");
    end;

    local procedure ValidateAge()
    begin
        if "Date of Birth" = 0D then
            Error('Please provide a date of birth.');
        if not (Round(("Date Joined" - "Date of Birth") / 365.2364, 1, '<') in [18 .. 65]) then
            Error('A member must be between 18 and 65 at the time of joining.');
    end;

    procedure AssistEdit(xMember: Record "PEN Member") Result: Boolean
    var
        PENMember: Record "PEN Member";
    begin
        PENMember.Copy(Rec);
        PENSetup.Get();
        PENSetup.TestField("Member Nos.");
        "No." := NoSeries.GetNextNo(PENSetup."Member Nos.");
        Rec := PENMember;
        exit(true);
    end;
}
