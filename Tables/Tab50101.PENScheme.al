table 50101 "PEN Scheme"
{
    Caption = 'PEN Scheme';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            NotBlank = true;
        }
        field(3; "Scheme Type"; Enum "PEN Scheme Type")
        {
            Caption = 'Scheme Type';
        }
        field(4; "Employer Cap %"; Decimal)
        {
            Caption = 'Employer Cap %';
        }
        field(5; "Contribution Receivable Acc."; Code[20])
        {
            Caption = 'Contribution Receivable Acc.';
            TableRelation = "G/L Account";
        }
        field(6; "Member Liability Acc."; Code[20])
        {
            Caption = 'Member Liability Acc.';
            TableRelation = "G/L Account";
        }
        field(7; "Penalty Income Acc."; Code[20])
        {
            Caption = 'Penalty Income Acc.';
            TableRelation = "G/L Account";
        }
        field(8; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
