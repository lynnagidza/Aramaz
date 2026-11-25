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
        field(5; "Remittance Due Day "; Integer)
        {
            Caption = 'Remittance Due Day ';
            InitValue = 9;
        }
        field(6; "Late Penalty % "; Decimal)
        {
            Caption = 'Late Penalty % ';
        }
        field(7; "Queue Batch Size "; Integer)
        {
            Caption = 'Queue Batch Size ';
            InitValue = 500;
        }
        field(8; "Max Retry Attempts "; Integer)
        {
            Caption = 'Max Retry Attempts ';
            InitValue = 3;
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
