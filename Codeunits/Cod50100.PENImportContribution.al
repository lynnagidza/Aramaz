codeunit 50100 "PEN Import Contribution"
{
    var
        Batch: Record "PEN Contribution Batch";
        Queue: Record "PEN Contribution Queue";
        CSVBuffer: Record "CSV Buffer" temporary;
        MessageID, EmployerNo, MemberNo : Code[20];
        ImportPeriod: Code[7];
        ControlTotal, EmployeeTotal, EmployerTotal : Decimal;
        EmployeeAmount, EmployerAmount : Decimal;
        ReceivedDate: Date;
        MembersInFile: Dictionary of [Code[20], Boolean];

    procedure ImportCSV(IStream: InStream)
    var
        LineNo, DataLineCount, FirstDataRow : Integer;
        MessageIDText, EmployerNoText, PeriodText : Text;
    begin
        ResetImportState();

        CSVBuffer.Reset();
        CSVBuffer.DeleteAll();
        CSVBuffer.LoadDataFromStream(IStream, ',');

        if CSVBuffer.GetNumberOfLines() < 2 then
            Error('The CSV file does not contain any contribution lines.');

        FirstDataRow := FindFirstDataRow();

        if FirstDataRow = 0 then
            Error('The CSV file does not contain any contribution lines.');

        // Read and validate the header from the first data row
        MessageIDText := GetValueAtCell(FirstDataRow, 1);
        EmployerNoText := GetValueAtCell(FirstDataRow, 2);
        PeriodText := GetValueAtCell(FirstDataRow, 3);

        if MessageIDText = '' then
            Error('Message ID is missing.');

        if StrLen(MessageIDText) > MaxStrLen(MessageID) then
            Error('Message ID exceeds the maximum length of %1 characters.', MaxStrLen(MessageID));

        if EmployerNoText = '' then
            Error('Employer No. is missing.');

        if StrLen(EmployerNoText) > MaxStrLen(EmployerNo) then
            Error('Employer No. exceeds the maximum length of %1 characters.', MaxStrLen(EmployerNo));

        if PeriodText = '' then
            Error('Contribution period is missing.');

        if StrLen(PeriodText) > MaxStrLen(ImportPeriod) then
            Error('Contribution period has an invalid length.');

        MessageID := MessageIDText;
        EmployerNo := EmployerNoText;
        ImportPeriod := PeriodText;

        ValidatePeriod();

        if not Evaluate(ReceivedDate, GetValueAtCell(FirstDataRow, 4)) then
            Error('Invalid received date on row %1.', FirstDataRow);

        if not Evaluate(ControlTotal, GetValueAtCell(FirstDataRow, 5)) then
            Error('Invalid control total on row %1.', FirstDataRow);

        if ControlTotal < 0 then
            Error('Control total cannot be negative.');

        GetOrCreateBatch();

        // Process and validate each line
        for LineNo := FirstDataRow to CSVBuffer.GetNumberOfLines() do begin
            if IsEmptyCSVRow(LineNo) then
                continue;

            if not Evaluate(EmployeeAmount, GetValueAtCell(LineNo, 7)) then
                Error('Invalid employee amount on row %1.', LineNo);

            if not Evaluate(EmployerAmount, GetValueAtCell(LineNo, 8)) then
                Error('Invalid employer amount on row %1.', LineNo);

            ProcessContributionLine(GetValueAtCell(LineNo, 6), EmployeeAmount, EmployerAmount, LineNo);
            DataLineCount += 1;
        end;

        ValidateControlTotal(DataLineCount);
    end;

    procedure ImportJSON(IStream: InStream)
    var
        JsonObj: JsonObject;
        JsonObjLine: JsonObject;
        JsonArr: JsonArray;
        JsonTok: JsonToken;
        LineNo, DataLineCount : Integer;
        MessageIDText, EmployerNoText, PeriodText, ReceivedDateText : Text;
    begin
        ResetImportState();

        // Read and parse the JSON stream
        if not JsonObj.ReadFrom(IStream) then
            Error('The JSON file is invalid.');

        // Read and validate header details
        MessageIDText := GetJsonText(JsonObj, 'messageId');
        EmployerNoText := GetJsonText(JsonObj, 'employerNo');
        PeriodText := GetJsonText(JsonObj, 'period');
        ReceivedDateText := GetJsonText(JsonObj, 'receivedDate');

        if MessageIDText = '' then
            Error('Message ID is missing.');

        if StrLen(MessageIDText) > MaxStrLen(MessageID) then
            Error('Message ID exceeds the maximum length of %1 characters.', MaxStrLen(MessageID));

        if EmployerNoText = '' then
            Error('Employer No. is missing.');

        if StrLen(EmployerNoText) > MaxStrLen(EmployerNo) then
            Error('Employer No. exceeds the maximum length of %1 characters.', MaxStrLen(EmployerNo));

        if PeriodText = '' then
            Error('Contribution period is missing.');

        if StrLen(PeriodText) > MaxStrLen(ImportPeriod) then
            Error('Contribution period has an invalid length.');

        MessageID := MessageIDText;
        EmployerNo := EmployerNoText;
        ImportPeriod := PeriodText;

        ValidatePeriod();

        if not Evaluate(ReceivedDate, ReceivedDateText) then
            Error('Invalid received date.');

        ControlTotal := GetJsonDecimal(JsonObj, 'controlTotal');

        if ControlTotal < 0 then
            Error('Control total cannot be negative.');

        GetOrCreateBatch();

        // Retrieve and validate the lines array
        if not JsonObj.Get('lines', JsonTok) then
            Error('The JSON file does not contain a lines array.');

        if not JsonTok.IsArray() then
            Error('The lines property must be a JSON array.');

        JsonArr := JsonTok.AsArray();

        if JsonArr.Count() = 0 then
            Error('The JSON file does not contain any contribution lines.');

        // Process each contribution line
        for LineNo := 0 to JsonArr.Count() - 1 do begin
            if not JsonArr.Get(LineNo, JsonTok) then
                Error('Unable to read contribution line %1.', LineNo + 1);

            if not JsonTok.IsObject() then
                Error('Contribution line %1 must be a JSON object.', LineNo + 1);

            JsonObjLine := JsonTok.AsObject();

            MemberNo := GetJsonText(JsonObjLine, 'memberNo');
            EmployeeAmount := GetJsonDecimal(JsonObjLine, 'employeeAmount');
            EmployerAmount := GetJsonDecimal(JsonObjLine, 'employerAmount');

            ProcessContributionLine(MemberNo, EmployeeAmount, EmployerAmount, LineNo + 1);
            DataLineCount += 1;
        end;

        ValidateControlTotal(DataLineCount);
    end;

    local procedure ResetImportState()
    begin
        Clear(MessageID);
        Clear(EmployerNo);
        Clear(MemberNo);
        Clear(ImportPeriod);
        Clear(ControlTotal);
        Clear(EmployeeTotal);
        Clear(EmployerTotal);
        Clear(EmployeeAmount);
        Clear(EmployerAmount);
        Clear(ReceivedDate);
        Clear(MembersInFile);
        Batch.Reset();
        Queue.Reset();
    end;

    local procedure GetOrCreateBatch()
    begin
        Batch.Reset();
        Batch.SetRange("Message Id", MessageID);

        if Batch.FindFirst() then begin
            if Batch."Employer No." <> EmployerNo then
                Error('The existing batch has a different employer.');

            if Batch.Period <> ImportPeriod then
                Error('The existing batch has a different period.');

            if Batch."Received Date" <> ReceivedDate then
                Error('The existing batch has a different received date.');

            if Batch."Control Total" <> ControlTotal then
                Error('The existing batch has a different control total.');
        end else begin
            Batch.Init();
            Batch.Validate("Message Id", MessageID);
            Batch.Validate("Employer No.", EmployerNo);
            Batch.Validate(Period, ImportPeriod);
            Batch.Validate("Received Date", ReceivedDate);
            Batch.Validate("Control Total", ControlTotal);
            Batch.Insert(true);
        end;
    end;

    local procedure ProcessContributionLine(NewMemberNo: Text; NewEmployeeAmount: Decimal; NewEmployerAmount: Decimal; SourceLineNo: Integer)
    begin
        if NewMemberNo = '' then
            Error('Member No. is missing on line %1.', SourceLineNo);

        if StrLen(NewMemberNo) > MaxStrLen(MemberNo) then
            Error('Member No. exceeds the maximum length on line %1.', SourceLineNo);

        MemberNo := NewMemberNo;

        if MembersInFile.ContainsKey(MemberNo) then
            Error('Member %1 appears more than once in the uploaded file.', MemberNo);

        MembersInFile.Add(MemberNo, true);

        if (NewEmployeeAmount < 0) or (NewEmployerAmount < 0) then
            Error('Contribution amounts cannot be negative. Line %1.', SourceLineNo);

        EmployeeAmount := NewEmployeeAmount;
        EmployerAmount := NewEmployerAmount;

        EmployeeTotal += EmployeeAmount;
        EmployerTotal += EmployerAmount;

        // Preserve existing queue lines during partial re-imports.... however, if more info is provided, allow user to select override or maintain older data (assumption is once uploaded, that's it!)
        Queue.Reset();
        Queue.SetCurrentKey("Batch No.", "Member No.");
        Queue.SetRange("Batch No.", Batch."No.");
        Queue.SetRange("Member No.", MemberNo);
        if not Queue.FindFirst() then begin
            Queue.Init();
            Queue.Validate("Batch No.", Batch."No.");
            Queue.Validate("Member No.", MemberNo);
            Queue.Validate("Employee Amount", EmployeeAmount);
            Queue.Validate("Employer Amount", EmployerAmount);
            Queue.Validate(Period, ImportPeriod);
            Queue.Validate(Status, Enum::"PEN Contribution Queue Status"::Pending);
            Queue.Insert(true);
        end;
    end;

    local procedure ValidateControlTotal(DataLineCount: Integer)
    begin
        if DataLineCount = 0 then
            Error('The file does not contain any contribution lines.');

        if AmountMismatch(ControlTotal, EmployeeTotal, EmployerTotal) then
            Error('Control total mismatch. Expected %1, but the contribution total is %2.', ControlTotal, EmployeeTotal + EmployerTotal);
    end;

    local procedure ValidatePeriod()
    var
        YearNo: Integer;
        MonthNo: Integer;
    begin
        if StrLen(ImportPeriod) <> 7 then
            Error('Contribution period must use YYYY-MM format.');

        if CopyStr(ImportPeriod, 5, 1) <> '-' then
            Error('Contribution period must use YYYY-MM format.');

        if not Evaluate(YearNo, CopyStr(ImportPeriod, 1, 4)) then
            Error('Invalid contribution year.');

        if not Evaluate(MonthNo, CopyStr(ImportPeriod, 6, 2)) then
            Error('Invalid contribution month.');

        if (YearNo < 1753) or (MonthNo < 1) or (MonthNo > 12) then
            Error('Invalid contribution period.');
    end;

    local procedure FindFirstDataRow(): Integer
    var
        RowNo: Integer;
    begin
        for RowNo := 2 to CSVBuffer.GetNumberOfLines() do
            if not IsEmptyCSVRow(RowNo) then
                exit(RowNo);
        exit(0);
    end;

    local procedure IsEmptyCSVRow(RowNo: Integer): Boolean
    var
        ColNo: Integer;
    begin
        for ColNo := 1 to 8 do
            if GetValueAtCell(RowNo, ColNo) <> '' then
                exit(false);
        exit(true);
    end;

    local procedure GetValueAtCell(RowNo: Integer; ColNo: Integer): Text
    begin
        if CSVBuffer.Get(RowNo, ColNo) then
            exit(CSVBuffer.Value);

        exit('');
    end;

    local procedure GetJsonText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyName, JToken) then
            Error('Required JSON property %1 is missing.', PropertyName);

        if not JToken.IsValue() then
            Error('JSON property %1 must contain a value.', PropertyName);

        if JToken.AsValue().IsNull() then
            Error('JSON property %1 cannot be null.', PropertyName);

        exit(JToken.AsValue().AsText());
    end;

    local procedure GetJsonDecimal(JObject: JsonObject; PropertyName: Text): Decimal
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyName, JToken) then
            Error('Required JSON property %1 is missing.', PropertyName);

        if not JToken.IsValue() then
            Error('JSON property %1 must contain a numeric value.', PropertyName);

        if JToken.AsValue().IsNull() then
            Error('JSON property %1 cannot be null.', PropertyName);

        exit(JToken.AsValue().AsDecimal());
    end;

    local procedure AmountMismatch(ExpectedTotal: Decimal; TotalEmployeeAmount: Decimal; TotalEmployerAmount: Decimal): Boolean
    begin
        exit(ExpectedTotal <> (TotalEmployeeAmount + TotalEmployerAmount));
    end;
}