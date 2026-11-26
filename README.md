# Aramaz - Pension Scheme Management

## Implemented design

- Master data uses the PEN object prefix and object IDs 50100-50149.
- Duplicate member National IDs and employer KRA PINs are rejected by table validation.
- Member and employer FlowFields are filtered by member or employer.
- CSV and JSON intake both support structural validation and control-total validation.
- A batch is created only after all file structural checks and control-total checks succeed.
- A batch `Message Id` is unique and rejected on resubmission.
- Queue lines remain `Pending` until a processing job claims them.
- Queue processing validates member, employer, scheme, duplicate period posting, and employer cap.
- Failed lines receive retry counts and error text. At the configured retry limit they become `Dead Letter`.
- Selected Failed or Dead Letter queue lines can be reset to `Pending` from the queue page.
- Posted lines create two `PEN Member Ledger Entry` records. Batch G/L posting creates the contribution receivable and member liability pair once the batch has no pending or processing lines.
- Late batches create one receivable/penalty-income pair, based on the setup late penalty percentage and the due day in the month following the contribution period.

## Double processing

The processor locks the queue table and claims one `Pending` line by changing it to `Processing` before validation and posting. A line is only selected again after it has returned to `Pending` or `Failed`. The batch and message ID have unique keys, the queue prevents duplicate member lines, and posted lines are checked before posting. For stronger protection across two Job Queue entries, only one entry should be scheduled for production until processing has been made line-claim safe across concurrent sessions. If concurrent entries are enabled, extend the claim with a dedicated Job Queue process lock or a unique Processing Batch/Lease field and compare-and-claim it.

## Reconciliation

For a batch, posted employee and employer ledger totals must equal the successful queue ledger entries. The G/L member-liability credit is the sum of successfully posted employee and employer amounts. Traceability is preserved through the batch number and document number on every member ledger entry and journal line.
