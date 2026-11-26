page 50108 "PEN Member Ledger Entries"
{
    ApplicationArea = All;
    Caption = 'PEN Member Ledger Entries';
    PageType = List;
    SourceTable = "PEN Member Ledger Entry";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Member No."; Rec."Member No.") { }
                field("Employer No."; Rec."Employer No.") { }
                field("Scheme Code"; Rec."Scheme Code") { }
                field("Posting Date"; Rec."Posting Date") { }
                field(Period; Rec.Period) { }
                field("Entry Type"; Rec."Entry Type") { }
                field(Amount; Rec.Amount) { }
                field("Batch No."; Rec."Batch No.") { }
                field("Document No."; Rec."Document No.") { }
                field("Posted By"; Rec."Posted By") { }
                field("Posted At"; Rec."Posted At") { }
            }
        }
    }
}
