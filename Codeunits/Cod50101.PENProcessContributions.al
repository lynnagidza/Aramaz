codeunit 50101 "PEN Process Contributions"
{
    trigger OnRun()
    begin
        ProcessPendingContributions();
    end;

    var
        PENBatch: Record "PEN Contribution Batch";
        PENSetup: Record "PEN Pension Setup";
        PENEmployer: Record "PEN Employer";
        PENScheme: Record "PEN Scheme";
        ProcessingQueue: Record "PEN Contribution Queue";


    local procedure ProcessPendingContributions()
    var
        BatchNo: Code[20];
    begin
        PENSetup.Get();
        PENSetup.TestField("Queue Batch Size");
        PENSetup.TestField("Max Retry Attempts");
        PENSetup.TestField("G/L Journal Template");
        PENSetup.TestField("G/L Journal Batch");

        while true do begin
            BatchNo := GetNextPendingBatchNo();
            if BatchNo = '' then
                exit;

            if HasPendingLines(BatchNo) then begin
                ProcessBatchChunk(BatchNo);
                Commit();
            end;

            if not HasUnprocessedLines(BatchNo) then begin
                PostGLSummary(BatchNo);
                Commit();
            end;
        end;
    end;


    local procedure GetNextPendingBatchNo(): Code[20]
    var
        Queue: Record "PEN Contribution Queue";
        Batch: Record "PEN Contribution Batch";
    begin
        Queue.LockTable();
        Queue.SetRange(Status, Queue.Status::Pending);
        if Queue.FindFirst() then
            exit(Queue."Batch No.");

        Batch.LockTable();
        Batch.SetFilter(
            "G/L Summary Status", '%1|%2', Batch."G/L Summary Status"::Pending, Batch."G/L Summary Status"::Failed);
        if Batch.FindSet() then
            repeat
                if not HasUnprocessedLines(Batch."No.") then
                    exit(Batch."No.");
            until Batch.Next() = 0;
        exit('');
    end;

    local procedure HasPendingLines(BatchNo: Code[20]): Boolean
    var
        Queue: Record "PEN Contribution Queue";
    begin
        Queue.SetRange("Batch No.", BatchNo);
        Queue.SetRange(Status, Queue.Status::Pending);
        exit(not Queue.IsEmpty());
    end;

    local procedure ProcessBatchChunk(BatchNo: Code[20])
    var
        QueueLine: Record "PEN Contribution Queue";
        CurrBatchSize: Integer;
    begin
        QueueLine.LockTable();

        while CurrBatchSize < PENSetup."Queue Batch Size" do begin
            QueueLine.Reset();
            QueueLine.SetRange("Batch No.", BatchNo);
            QueueLine.SetRange(Status, QueueLine.Status::Pending);
            if not QueueLine.FindFirst() then
                exit;
            if QueueLine.Get(BatchNo, QueueLine."Line No.") then begin
                if QueueLine.Status <> QueueLine.Status::Pending then
                    continue;
                QueueLine.Validate(Status, QueueLine.Status::Processing);
                QueueLine.Modify();
            end;

            ProcessQueueLine(QueueLine);
            CurrBatchSize += 1;
        end;
    end;

    local procedure ProcessQueueLine(var Queue: Record "PEN Contribution Queue")
    begin
        OnBeforeValidateQueueLine(Queue);

        // one failing line should not stop the other lines in its batch, and its error text is stored on the line
        if not PENBatch.Get(Queue."Batch No.") then begin
            HandleProcessingError(Queue, 'Contribution batch does not exist.');
            exit;
        end;

        if not ActiveMemberExists(Queue."Member No.") then begin
            HandleProcessingError(Queue, 'Member does not exist, is inactive, or does not belong to the batch employer.');
            exit;
        end;

        if not ActiveEmployerAndScheme() then begin
            HandleProcessingError(Queue, 'Employer is inactive or the scheme is blocked.');
            exit;
        end;

        if not NoPostedLineExists(Queue."Member No.", Queue.Period) then begin
            HandleProcessingError(Queue, 'A contribution has already been posted for this member and period.');
            exit;
        end;

        if Queue."Employer Amount" > EmployerAmountCapCalculation(Queue."Member No.") then begin
            HandleProcessingError(Queue, 'Employer contribution exceeds the scheme cap.');
            exit;
        end;

        ProcessingQueue := Queue;
        if not TryPostContribution() then begin
            HandleProcessingError(Queue, CopyStr(GetLastErrorText(), 1, 2048));
            exit;
        end;

        Queue.Validate(Status, Enum::"PEN Contribution Queue Status"::Posted);
        Queue.Modify();
        OnAfterPostQueueLine(Queue);
    end;

    [TryFunction]
    local procedure TryPostContribution()
    begin
        PostContribution(ProcessingQueue);
    end;

    local procedure ActiveMemberExists(MemberNo: Code[20]): Boolean
    var
        PENMember: Record "PEN Member";
    begin
        if not PENMember.Get(MemberNo) then
            exit(false);
        exit((PENMember.Status = PENMember.Status::Active) and (PENMember."Employer No." = PENBatch."Employer No."));
    end;

    local procedure ActiveEmployerAndScheme(): Boolean
    var
    begin
        if not PENEmployer.Get(PENBatch."Employer No.") then
            exit(false);
        if not PENScheme.Get(PENEmployer."Scheme Code") then
            exit(false);
        exit((PENEmployer.Status = PENEmployer.Status::Active) and not PENScheme.Blocked);
    end;

    local procedure NoPostedLineExists(MemberNo: Code[20]; Period: Code[7]): Boolean
    var
        LocalQueue: Record "PEN Contribution Queue";
    begin
        LocalQueue.SetRange("Member No.", MemberNo);
        LocalQueue.SetRange(Period, Period);
        LocalQueue.SetRange(Status, Enum::"PEN Contribution Queue Status"::Posted);
        exit(LocalQueue.IsEmpty);
    end;

    local procedure EmployerAmountCapCalculation(MemberNo: Code[20]): Decimal
    var
        PENMember: Record "PEN Member";
    begin
        if not PENMember.Get(MemberNo) then
            exit(0);
        if not PENEmployer.Get(PENMember."Employer No.") then
            exit(0);
        if not PENScheme.Get(PENEmployer."Scheme Code") then
            exit(0);
        exit(PENMember."Pensionable Salary" * (PENScheme."Employer Cap %" / 100));
    end;

    local procedure PostContribution(var Queue: Record "PEN Contribution Queue")
    var
        MemberLedgerEntry: Record "PEN Member Ledger Entry";
        Year, Month : Integer;
        PostingDate: Date;
        DocumentNo: Code[20];
        PostedAt: DateTime;
    begin
        Evaluate(Year, CopyStr(Queue.Period, 1, 4));
        Evaluate(Month, CopyStr(Queue.Period, 6, 2));

        PostingDate := CalcDate('<CM>', DMY2Date(1, Month, Year));

        DocumentNo := Queue."Batch No.";
        PostedAt := CurrentDateTime;

        // Employee contribution
        MemberLedgerEntry.Init();
        MemberLedgerEntry.Validate("Member No.", Queue."Member No.");
        MemberLedgerEntry.Validate("Employer No.", PENBatch."Employer No.");
        MemberLedgerEntry.Validate("Scheme Code", PENEmployer."Scheme Code");
        MemberLedgerEntry.Validate(Period, Queue.Period);
        MemberLedgerEntry.Validate("Posting Date", PostingDate);
        MemberLedgerEntry.Validate(Amount, Queue."Employee Amount");
        MemberLedgerEntry.Validate("Entry Type", MemberLedgerEntry."Entry Type"::"Employee Contribution");
        MemberLedgerEntry.Validate("Batch No.", Queue."Batch No.");
        MemberLedgerEntry.Validate("Document No.", DocumentNo);
        MemberLedgerEntry."Posted By" := UserId;
        MemberLedgerEntry."Posted At" := PostedAt;
        MemberLedgerEntry.Insert(true);

        // Employer contribution
        MemberLedgerEntry.Init();
        MemberLedgerEntry.Validate("Member No.", Queue."Member No.");
        MemberLedgerEntry.Validate("Employer No.", PENBatch."Employer No.");
        MemberLedgerEntry.Validate("Scheme Code", PENEmployer."Scheme Code");
        MemberLedgerEntry.Validate(Period, Queue.Period);
        MemberLedgerEntry.Validate("Posting Date", PostingDate);
        MemberLedgerEntry.Validate(Amount, Queue."Employer Amount");
        MemberLedgerEntry.Validate("Entry Type", MemberLedgerEntry."Entry Type"::"Employer Contribution");
        MemberLedgerEntry.Validate("Batch No.", Queue."Batch No.");
        MemberLedgerEntry.Validate("Document No.", DocumentNo);
        MemberLedgerEntry."Posted By" := UserId;
        MemberLedgerEntry."Posted At" := PostedAt;
        MemberLedgerEntry.Insert(true);
    end;

    local procedure PostGLSummary(BatchNo: Code[20])
    var
        Batch: Record "PEN Contribution Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        EmployeeTotal, EmployerTotal, EmployeeToPost, EmployerToPost, TotalToPost, PenaltyAmount : Decimal;
        Year, Month : Integer;
        PostingDate: Date;
        LateBatch: Boolean;
        HasJournalLines: Boolean;
    begin
        Batch.LockTable();
        if not Batch.Get(BatchNo) then
            Error('Contribution batch %1 does not exist.', BatchNo);

        if HasUnprocessedLines(BatchNo) then
            exit;

        Batch.CalcFields("Posted Employee Contributions", "Posted Employer Contributions");

        EmployeeTotal := Batch."Posted Employee Contributions";
        EmployerTotal := Batch."Posted Employer Contributions";
        EmployeeToPost := EmployeeTotal - Batch."G/L Employee Amount";
        EmployerToPost := EmployerTotal - Batch."G/L Employer Amount";

        if (EmployeeToPost < 0) or (EmployerToPost < 0) then
            Error('The G/L summary amounts exceed the posted member contributions for batch %1.', BatchNo);

        TotalToPost := EmployeeToPost + EmployerToPost;

        if not PENEmployer.Get(Batch."Employer No.") then
            Error('Employer %1 does not exist.', Batch."Employer No.");

        if not PENScheme.Get(PENEmployer."Scheme Code") then
            Error('Scheme %1 does not exist.', PENEmployer."Scheme Code");

        PENScheme.TestField("Contribution Receivable Acc.");
        PENScheme.TestField("Member Liability Acc.");

        LateBatch := IsLateBatch(Batch);
        if LateBatch and not Batch."Penalty Posted" then begin
            PENSetup.TestField("Late Penalty %");
            PENScheme.TestField("Penalty Income Acc.");
            PenaltyAmount := Round(Batch."Control Total" * PENSetup."Late Penalty %" / 100, 0.01);
        end;

        if (TotalToPost = 0) and (PenaltyAmount = 0) then begin
            Batch.Validate("G/L Summary Status", Batch."G/L Summary Status"::Posted);
            Batch.Modify();
            exit;
        end;

        if not GenJnlBatch.Get(PENSetup."G/L Journal Template", PENSetup."G/L Journal Batch") then
            Error('The configured General Journal Batch does not exist.');

        GenJnlLine.SetRange("Journal Template Name", PENSetup."G/L Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", PENSetup."G/L Journal Batch");

        if not GenJnlLine.IsEmpty() then
            Error('The configured General Journal Batch must be empty before pension summary posting.');

        Evaluate(Year, CopyStr(Batch.Period, 1, 4));
        Evaluate(Month, CopyStr(Batch.Period, 6, 2));

        PostingDate := CalcDate('<CM>', DMY2Date(1, Month, Year));

        if TotalToPost <> 0 then begin
            CreateGLJournalLine(GenJnlLine, 10000, PENSetup."G/L Journal Template", PENSetup."G/L Journal Batch", PENScheme."Contribution Receivable Acc.", TotalToPost, BatchNo, PostingDate, 'Pension contribution summary ' + BatchNo);
            CreateGLJournalLine(GenJnlLine, 20000, PENSetup."G/L Journal Template", PENSetup."G/L Journal Batch", PENScheme."Member Liability Acc.", -TotalToPost, BatchNo, PostingDate, 'Pension contribution summary ' + BatchNo);
            HasJournalLines := true;
        end;

        if PenaltyAmount <> 0 then begin
            CreateGLJournalLine(GenJnlLine, 30000, PENSetup."G/L Journal Template", PENSetup."G/L Journal Batch", PENScheme."Contribution Receivable Acc.", PenaltyAmount, BatchNo, PostingDate, 'Late penalty - employer ' + Batch."Employer No.");
            CreateGLJournalLine(GenJnlLine, 40000, PENSetup."G/L Journal Template", PENSetup."G/L Journal Batch", PENScheme."Penalty Income Acc.", -PenaltyAmount, BatchNo, PostingDate, 'Late penalty - employer ' + Batch."Employer No.");
            HasJournalLines := true;
        end;

        if not HasJournalLines then begin
            Batch.Validate("G/L Summary Status", Batch."G/L Summary Status"::Posted);
            Batch.Modify();
            exit;
        end;

        GenJnlLine.SetRange("Journal Template Name", PENSetup."G/L Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", PENSetup."G/L Journal Batch");

        if not TryPostGLSummary() then begin
            Batch.Validate("G/L Summary Status", Batch."G/L Summary Status"::Failed);
            Batch.Modify();
            exit;
        end;

        Batch.Validate("G/L Employee Amount", EmployeeTotal);
        Batch.Validate("G/L Employer Amount", EmployerTotal);
        if PenaltyAmount <> 0 then begin
            Batch.Validate("Penalty Amount", PenaltyAmount);
            Batch.Validate("Penalty Posted", true);
        end;
        Batch.Validate("G/L Summary Status", Batch."G/L Summary Status"::Posted);
        Batch.Modify();
    end;

    [TryFunction]
    local procedure TryPostGLSummary()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
    begin
        GenJnlLine.SetRange("Journal Template Name", PENSetup."G/L Journal Template");
        GenJnlLine.SetRange("Journal Batch Name", PENSetup."G/L Journal Batch");
        GenJnlPostBatch.SetSuppressCommit(true);
        GenJnlPostBatch.Run(GenJnlLine);
    end;

    local procedure IsLateBatch(Batch: Record "PEN Contribution Batch"): Boolean
    var
        Year, Month : Integer;
        DueDate: Date;
    begin
        PENSetup.TestField("Remittance Due Day");
        Evaluate(Year, CopyStr(Batch.Period, 1, 4));
        Evaluate(Month, CopyStr(Batch.Period, 6, 2));
        Month += 1;
        if Month > 12 then begin
            Month := 1;
            Year += 1;
        end;
        DueDate := DMY2Date(PENSetup."Remittance Due Day", Month, Year);
        exit(Batch."Received Date" > DueDate);
    end;

    local procedure CreateGLJournalLine(var GenJnlLine: Record "Gen. Journal Line"; LineNo: Integer; TemplateName: Code[10]; BatchName: Code[10]; AccountNo: Code[20]; Amount: Decimal; DocumentNo: Code[20]; PostingDate: Date; JournalDescription: Text)
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Journal Template Name", TemplateName);
        GenJnlLine.Validate("Journal Batch Name", BatchName);
        GenJnlLine."Line No." := LineNo;
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        GenJnlLine.Validate("Account No.", AccountNo);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Document No.", DocumentNo);
        GenJnlLine.Validate(Description, CopyStr(JournalDescription, 1, MaxStrLen(GenJnlLine.Description)));
        GenJnlLine.Validate(Amount, Amount);
        GenJnlLine.Insert(true);
    end;

    local procedure HasUnprocessedLines(BatchNo: Code[20]): Boolean
    var
        Queue: Record "PEN Contribution Queue";
    begin
        Queue.SetRange("Batch No.", BatchNo);
        Queue.SetFilter(Status, '%1|%2', Queue.Status::Pending, Queue.Status::Processing);
        exit(not Queue.IsEmpty());
    end;

    local procedure HandleProcessingError(var Queue: Record "PEN Contribution Queue"; ErrorMessage: Text)
    begin
        Queue."Retry Count" += 1;
        Queue."Last Error" := CopyStr(ErrorMessage, 1, MaxStrLen(Queue."Last Error"));

        // Failed lines are retried, and after Max Retry Attempts they move to Dead Letter
        if Queue."Retry Count" >= PENSetup."Max Retry Attempts" then
            Queue.Validate(Status, Enum::"PEN Contribution Queue Status"::"Dead Letter")
        else
            Queue.Validate(Status, Enum::"PEN Contribution Queue Status"::Failed);

        Queue.Modify();
    end;


    procedure Reprocess(var QueueToReprocess: Record "PEN Contribution Queue")
    var
        Queue: Record "PEN Contribution Queue";
        Batch: Record "PEN Contribution Batch";
    begin
        if QueueToReprocess.FindSet() then
            repeat
                if (QueueToReprocess.Status = QueueToReprocess.Status::Failed) or
                   (QueueToReprocess.Status = QueueToReprocess.Status::"Dead Letter")
                then begin
                    Queue := QueueToReprocess;
                    Queue.Validate(Status, Queue.Status::Pending);
                    Queue.Validate("Retry Count", 0);
                    Queue.Validate("Last Error", '');
                    Queue.Modify();

                    if Batch.Get(Queue."Batch No.") then begin
                        Batch.Validate("G/L Summary Status", Batch."G/L Summary Status"::Pending);
                        Batch.Modify();
                    end;
                end;
            until QueueToReprocess.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeValidateQueueLine(var Queue: Record "PEN Contribution Queue")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterPostQueueLine(var Queue: Record "PEN Contribution Queue")
    begin
    end;

}
