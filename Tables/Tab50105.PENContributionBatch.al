table 50105 "PEN Contribution Batch"
{
    Caption = 'PEN Contribution Batch';
    DataClassification = ToBeClassified;
    LookupPageId = "PEN Contribution Batches";
    DrillDownPageId = "PEN Contribution Batches";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            trigger OnValidate()
            begin
                if not ("No." = xRec."No.") then begin
                    PENSetup.Get();
                    NoSeries.TestManual(PENSetup."Contribution Batch Nos.");
                end;
                if "No." = '' then
                    InitRec();
            end;
        }
        field(2; "Message Id"; Code[20])
        {
            Caption = 'Message Id';
        }
        field(3; Period; Code[7])
        {
            Caption = 'Period';
        }
        field(4; "Received Date"; Date)
        {
            Caption = 'Received Date';
        }
        field(5; "Control Total"; Decimal)
        {
            Caption = 'Control Total';
        }
        field(6; "Employer No."; Code[20])
        {
            Caption = 'Employer No.';
            TableRelation = "PEN Employer";
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(EK; "Message Id")
        {
            Unique = true;
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
        PENSetup.TestField("Contribution Batch Nos.");
        if "No." = '' then
            "No." := NoSeries.GetNextNo(PENSetup."Contribution Batch Nos.");
    end;
}
