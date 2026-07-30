class AcademicCatalogOperation < ProfileAuditOperation
  private

  def safe_changes(record, fields)
    audited_changes(record, fields).each_with_object({}) do |(field, value), changes|
      changes[field] = if field.match?(/internal_notes|administrator_notes|placement_notes|exit_notes/)
                         { "changed" => true }
                       else
                         value
                       end
    end
  end
end
