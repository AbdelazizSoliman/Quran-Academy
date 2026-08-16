module Finance
  class Ledger
    def self.record_pair!(source:, actor:, debit:, credit:, entry:)
      common = entry.merge(source:, actor:)
      FinanceLedgerEntry.create!(common.merge(account: debit, direction: "debit"))
      FinanceLedgerEntry.create!(common.merge(account: credit, direction: "credit"))
    end

    private_class_method :new
  end
end
