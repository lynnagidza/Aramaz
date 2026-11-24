table 50104 "PEN Member Ledger Entry"
{
    Caption = 'PEN Member Ledger Entry';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Member No."; Code[20])
        {
            Caption = 'Member No.';
        }
        field(3; "Employer No."; Code[20])
        {
            Caption = 'Employer No.';
        }
        field(4; "Scheme Code"; Code[20])
        {
            Caption = 'Scheme Code';
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; Period; Code[7])
        {
            Caption = 'Period';
        }
        field(7; "Entry Type"; Enum "PEN Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(8; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(9; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
        }
        field(10; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(11; "Posted By"; Code[50])
        {
            Caption = 'Posted By';
        }
        field(12; "Posted At"; DateTime)
        {
            Caption = 'Posted At';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
