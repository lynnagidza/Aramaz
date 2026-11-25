table 50106 "PEN Contribution Queue"
{
    Caption = 'PEN Contribution Queue';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Batch No."; Code[20])
        {
            Caption = 'Batch No.';
            TableRelation = "PEN Contribution Batch";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Member No."; Code[20])
        {
            Caption = 'Member No.';
            TableRelation = "PEN Member";
        }
        field(4; "Employee Amount"; Decimal)
        {
            Caption = 'Employee Amount';
        }
        field(5; "Employer Amount"; Decimal)
        {
            Caption = 'Employer Amount';
        }
        field(6; Period; Code[7])
        {
            Caption = 'Period';
        }
        field(7; Status; Blob)//get correct type
        {
            Caption = 'Status';
        }
        field(8; "Retry Count"; Integer)
        {
            Caption = 'Retry Count';
        }
        field(9; "Last Error"; Text[2048])
        {
            Caption = 'Last Error';
        }
    }
    keys
    {
        key(PK; "Batch No.", "Line No.")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    begin
        InitRec();
    end;

    local procedure InitRec()
    var
        Queue: Record "PEN Contribution Queue";
    begin
        Queue.SetCurrentKey("Line No.");
        Queue.SetRange("Batch No.", "Batch No.");
        if Queue.FindLast() then
            "Line No." := Queue."Line No." + 10000
        else
            "Line No." := 10000;
    end;
}
