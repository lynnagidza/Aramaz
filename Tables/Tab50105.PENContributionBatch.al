table 50105 "PEN Contribution Batch"
{
    Caption = 'PEN Contribution Batch';
    DataClassification = ToBeClassified;
    LookupPageId = "PEN Contribution Batches";
    DrillDownPageId = "PEN Contribution Queues";

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
        field(7; "Total Employee Contributions"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("PEN Contribution Queue"."Employee Amount" where("Batch No." = field("No.")));
            Editable = false;
        }
        field(8; "Total Employer Contributions"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("PEN Contribution Queue"."Employer Amount" where("Batch No." = field("No.")));
            Editable = false;
        }
        field(9; "Posted Employee Contributions"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("PEN Member Ledger Entry".Amount where("Batch No." = field("No."), "Entry Type" = const("Employee Contribution")));
            Editable = false;
        }
        field(10; "Posted Employer Contributions"; Decimal)
        {
            FieldClass = FlowField;
            CalcFormula = sum("PEN Member Ledger Entry".Amount where("Batch No." = field("No."), "Entry Type" = const("Employer Contribution")));
            Editable = false;
        }
        field(11; "G/L Summary Status"; Enum "PEN Contribution Queue Status")
        {
            ValuesAllowed = Pending, Posted, Failed;
            InitValue = Pending;
        }
        field(12; "G/L Employee Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(13; "G/L Employer Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(14; "Penalty Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
        }
        field(15; "Penalty Posted"; Boolean)
        {
            DataClassification = ToBeClassified;
            InitValue = false;
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
