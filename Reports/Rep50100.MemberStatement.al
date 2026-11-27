report 50100 "Member Statement"
{
    Caption = 'Member Statement';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = StatementWord;
    dataset
    {
        dataitem(PENMember; "PEN Member")
        {
            RequestFilterFields = "No.", "National ID No.";
            column(MemberName; "First Name" + ' ' + "Last Name") { }
            column(No; "No.") { }
            column(NationalIDNo; "National ID No.") { }
            column(EmployerNo; "Employer No.") { }
            column(SchemeCode; "Scheme Code") { }
            column(StatementStartDate; StartDate) { }
            column(StatementEndDate; EndDate) { }
            column(OpeningBalance; OpeningBalance) { }
            column(ClosingBalance; ClosingBalance) { }
            column(TotalEmployeeAmount; TotalEmployeeAmount) { }
            column(TotalEmployerAmount; TotalEmployerAmount) { }

            trigger OnAfterGetRecord()
            begin
                //TODO build statement lines
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(StartDateField; StartDate)
                    {
                        Caption = 'Start Date';
                        ApplicationArea = All;
                    }
                    field(EndDateField; EndDate)
                    {
                        Caption = 'End Date';
                        ApplicationArea = All;
                    }
                }
            }
        }
    }
    rendering
    {
        layout(StatementWord)
        {
            Type = Word;
            LayoutFile = 'Reports/Layouts/MemberStatement.docx';
            Caption = 'Member Statement';
        }
        layout(StatementRDLC)
        {
            Type = RDLC;
            LayoutFile = 'Reports/Layouts/MemberStatement.rdlc';
            Caption = 'Member Statement';
        }
    }
    var
        MemberLedgerEntry: Record "PEN Member Ledger Entry";
        StartDate, EndDate : Date;
        OpeningBalance, ClosingBalance : Decimal;
        TotalEmployeeAmount, TotalEmployerAmount : Decimal;

    trigger OnInitReport()
    begin
        StartDate := CalcDate('<-CM>', Today);
        EndDate := CalcDate('<CM>', Today);
    end;

    trigger OnPreReport()
    begin
        if StartDate = 0D then
            Error('Enter a start date.');
        if EndDate = 0D then
            Error('Enter an end date.');
        if EndDate < StartDate then
            Error('The end date cannot be before the start date.');
    end;
}
