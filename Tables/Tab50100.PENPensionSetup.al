table 50100 "PEN Pension Setup"
{
    Caption = 'PEN Pension Setup';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Member Nos."; Code[20])
        {
            Caption = 'Member Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Employer Nos."; Code[20])
        {
            Caption = 'Employer Nos.';
            TableRelation = "No. Series";
        }
        field(4; "Contribution Batch Nos."; Code[20])
        {
            Caption = 'Contribution Batch Nos.';
            TableRelation = "No. Series";
        }
        field(5; "Remittance Due Day"; Integer)
        {
            Caption = 'Remittance Due Day';
            InitValue = 9;
            MinValue = 1;
            MaxValue = 28;//all months have at least 28 days
        }
        field(6; "Late Penalty %"; Decimal)
        {
            Caption = 'Late Penalty %';
            MinValue = 0;
            MaxValue = 100;
        }
        field(7; "Queue Batch Size"; Integer)
        {
            Caption = 'Queue Batch Size';
            InitValue = 500;
            MinValue = 1;
        }
        field(8; "Max Retry Attempts"; Integer)
        {
            Caption = 'Max Retry Attempts';
            InitValue = 3;
            MinValue = 1;
        }
        field(9; "G/L Journal Template"; Code[10])
        {
            TableRelation = "Gen. Journal Template";
            trigger OnValidate()
            begin
                "G/L Journal Batch" := '';
            end;
        }
        field(10; "G/L Journal Batch"; Code[10])
        {
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("G/L Journal Template"));
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
