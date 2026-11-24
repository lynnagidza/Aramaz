table 50102 "PEN Employer"
{
    Caption = 'PEN Employer';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
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
        }
        field(4; "KRA PIN"; Code[20])
        {
            Caption = 'KRA PIN';
            NotBlank = true;
            trigger OnValidate()
            begin
                // Format A000000000Z
                // should be unique
            end;
        }
        field(5; Email; Text[80])
        {
            Caption = 'Email';
            trigger OnValidate()
            begin
                // check format
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
            CalcFormula = count("PEN Member" where(Status = filter(Active)));
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
