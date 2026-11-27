codeunit 50103 "PEN Contribution Tests"
{
    Subtype = Test;

    [Test]
    procedure DuplicateMessageIdIsRejectedAtIntake()
    var
        Batch: Record "PEN Contribution Batch";
        TempBlob: Codeunit "Temp Blob";
        Importer: Codeunit "PEN Import Contribution";
        OutStream: OutStream;
        InStream: InStream;
        Payload: Text;
    begin
        Batch.Init();
        Batch."No." := 'EXISTING';
        Batch."Message Id" := 'DUPLICATE-MESSAGE';
        Batch.Period := CurrentPeriod();
        Batch."Employer No." := 'EMPTEST';
        Batch."Received Date" := Today;
        Batch."Control Total" := 0;
        Batch.Insert(false);

        Payload := StrSubstNo(
            '{"messageId":"DUPLICATE-MESSAGE","employerNo":"EMPTEST","period":"%1","receivedDate":"%2","controlTotal":0,"lines":[{"memberNo":"MEMTEST","employeeAmount":0,"employerAmount":0}]}',
            CurrentPeriod(), Format(Today, 0, '<Year4>-<Month,2>-<Day,2>'));
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText(Payload);
        TempBlob.CreateInStream(InStream);

        if TryImportJSON(Importer, InStream) then
            Error('Import should reject a previously received Message Id.');
        if StrPos(GetLastErrorText(), 'already been received') = 0 then
            Error('The intake error did not explain that the Message Id was already received. Actual error: %1', GetLastErrorText());
    end;

    [Test]
    procedure InvalidLineDoesNotStopValidLine()
    var
        Queue: Record "PEN Contribution Queue";
        LedgerEntry: Record "PEN Member Ledger Entry";
    begin
        CreateProcessingSetup();
        CreateSchemeEmployerAndMember();
        CreateBatch('BATCH-MIXED');
        CreateQueueLine('BATCH-MIXED', 10000, 'MEMBER-MISSING');
        CreateQueueLine('BATCH-MIXED', 20000, 'MEMBER-TEST');

        Codeunit.Run(Codeunit::"PEN Process Contributions");

        Queue.Get('BATCH-MIXED', 10000);
        if Queue.Status <> Queue.Status::Failed then
            Error('The invalid queue line should have Failed status.');
        if Queue."Last Error" = '' then
            Error('The invalid queue line should contain an error message.');

        Queue.Get('BATCH-MIXED', 20000);
        if Queue.Status <> Queue.Status::Posted then
            Error('The valid queue line should have Posted status.');

        LedgerEntry.SetRange("Member No.", 'MEMBER-TEST');
        if LedgerEntry.Count() <> 2 then
            Error('The valid line should create two member ledger entries.');
    end;

    [Test]
    procedure RepeatedFailureMovesLineToDeadLetter()
    var
        Queue: Record "PEN Contribution Queue";
    begin
        CreateProcessingSetup();
        CreateBatch('BATCH-RETRY');
        CreateQueueLine('BATCH-RETRY', 10000, 'MEMBER-MISSING');

        Codeunit.Run(Codeunit::"PEN Process Contributions");
        Queue.Get('BATCH-RETRY', 10000);
        if (Queue.Status <> Queue.Status::Failed) or (Queue."Retry Count" <> 1) then
            Error('The first failed attempt should leave the line Failed with retry count 1.');

        Queue.Validate(Status, Queue.Status::Pending);
        Queue.Modify(false);
        Codeunit.Run(Codeunit::"PEN Process Contributions");

        Queue.Get('BATCH-RETRY', 10000);
        if (Queue.Status <> Queue.Status::"Dead Letter") or (Queue."Retry Count" <> 2) then
            Error('The line should move to Dead Letter after the configured retry limit.');
    end;

    local procedure CreateProcessingSetup()
    var
        Setup: Record "PEN Pension Setup";
    begin
        Setup.Init();
        Setup."Primary Key" := 'TEST';
        Setup."Queue Batch Size" := 500;
        Setup."Max Retry Attempts" := 2;
        Setup."Remittance Due Day" := 9;
        Setup."G/L Journal Template" := 'TEMPLATE';
        Setup."G/L Journal Batch" := 'BATCH';
        Setup.Insert(false);
    end;

    local procedure CreateSchemeEmployerAndMember()
    var
        Scheme: Record "PEN Scheme";
        Employer: Record "PEN Employer";
        Member: Record "PEN Member";
    begin
        Scheme.Init();
        Scheme.Code := 'SCHEMETEST';
        Scheme.Description := 'Test Scheme';
        Scheme."Employer Cap %" := 10;
        Scheme.Insert(false);

        Employer.Init();
        Employer."No." := 'EMPTEST';
        Employer.Name := 'Test Employer';
        Employer."Scheme Code" := Scheme.Code;
        Employer."KRA PIN" := 'A123456789Z';
        Employer.Status := Employer.Status::Active;
        Employer.Insert(false);

        Member.Init();
        Member."No." := 'MEMBER-TEST';
        Member."First Name" := 'Test';
        Member."Last Name" := 'Member';
        Member."National ID No." := 'TEST-NATIONAL-ID';
        Member."Employer No." := Employer."No.";
        Member."Scheme Code" := Scheme.Code;
        Member."Date Joined" := Today;
        Member."Date of Birth" := CalcDate('<-30Y>', Today);
        Member."Pensionable Salary" := 50000;
        Member.Status := Member.Status::Active;
        Member.Insert(false);
    end;

    local procedure CreateBatch(BatchNo: Code[20])
    var
        Batch: Record "PEN Contribution Batch";
    begin
        Batch.Init();
        Batch."No." := BatchNo;
        Batch."Message Id" := BatchNo;
        Batch.Period := CurrentPeriod();
        Batch."Received Date" := Today;
        Batch."Employer No." := 'EMPTEST';
        Batch."Control Total" := 0;
        Batch."G/L Summary Status" := Batch."G/L Summary Status"::Pending;
        Batch.Insert(false);
    end;

    local procedure CreateQueueLine(BatchNo: Code[20]; LineNo: Integer; MemberNo: Code[20])
    var
        Queue: Record "PEN Contribution Queue";
    begin
        Queue.Init();
        Queue."Batch No." := BatchNo;
        Queue."Line No." := LineNo;
        Queue."Member No." := MemberNo;
        Queue."Employee Amount" := 0;
        Queue."Employer Amount" := 0;
        Queue.Period := CurrentPeriod();
        Queue.Status := Queue.Status::Pending;
        Queue.Insert(false);
    end;

    local procedure CurrentPeriod(): Code[7]
    begin
        exit(Format(Today, 0, '<Year4>-<Month,2>'));
    end;

    [TryFunction]
    local procedure TryImportJSON(var Importer: Codeunit "PEN Import Contribution"; var ImportedStream: InStream)
    begin
        Importer.ImportJSON(ImportedStream);
    end;
}
