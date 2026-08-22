module Admin
  module Users
    # Walks every :restrict (and undeclared, which behaves the same as :restrict at the
    # database level) foreign key transitively from a root row and deletes the whole
    # dependent subtree before the root itself, bypassing the protections those
    # constraints normally provide for regular application code.
    #
    # A handful of columns are optional cross-references rather than true ownership
    # (e.g. a student's assigned teacher) — those are nullified instead of cascaded,
    # so deleting a teacher never silently deletes an unrelated student's profile.
    class CascadingDelete
      CROSS_REFERENCE_COLUMNS = {
        "student_profiles" => %w[assigned_teacher_profile_id sibling_student_profile_id]
      }.freeze

      def self.reverse_restrict_graph
        @reverse_restrict_graph ||= build_reverse_restrict_graph
      end

      def self.build_reverse_restrict_graph
        connection = ActiveRecord::Base.connection
        graph = Hash.new { |hash, key| hash[key] = [] }
        connection.tables.each do |table|
          connection.foreign_keys(table).each do |fk|
            next if fk.on_delete.in?(%i[nullify cascade])
            next if CROSS_REFERENCE_COLUMNS.fetch(table, []).include?(fk.column)

            graph[fk.to_table] << { table: table, column: fk.column }
          end
        end
        graph
      end

      def initialize(table:, ids:)
        @connection = ActiveRecord::Base.connection
        @root_table = table
        @root_ids = Array(ids).map { |id| Integer(id) }
      end

      def call
        return if @root_ids.empty?

        layers = discover_layers
        nullify_cross_references(layers)
        delete_layers(layers)
      end

      private

      def discover_layers
        visited = Hash.new { |hash, key| hash[key] = Set.new }
        visited[@root_table].merge(@root_ids)
        frontier = { @root_table => @root_ids.to_set }
        layers = [frontier]

        loop do
          next_frontier = next_frontier_for(frontier, visited)
          break if next_frontier.values.all?(&:empty?)

          layers << next_frontier
          frontier = next_frontier
        end

        layers
      end

      def next_frontier_for(frontier, visited)
        next_frontier = Hash.new { |hash, key| hash[key] = Set.new }
        frontier.each do |table, ids|
          next if ids.empty?

          self.class.reverse_restrict_graph.fetch(table, []).each do |edge|
            found = referencing_ids(edge[:table], edge[:column], ids) - visited[edge[:table]].to_a
            next if found.empty?

            visited[edge[:table]].merge(found)
            next_frontier[edge[:table]].merge(found)
          end
        end
        next_frontier
      end

      def referencing_ids(table, column, parent_ids)
        @connection.select_values(<<~SQL.squish)
          SELECT id FROM #{@connection.quote_table_name(table)}
          WHERE #{@connection.quote_column_name(column)} IN (#{sql_id_list(parent_ids)})
        SQL
      end

      def nullify_cross_references(layers)
        deleted_ids_by_table = merge_layers(layers)
        CROSS_REFERENCE_COLUMNS.each do |table, columns|
          columns.each { |column| nullify_column(table, column, deleted_ids_by_table) }
        end
      end

      def nullify_column(table, column, deleted_ids_by_table)
        target_table = @connection.foreign_keys(table).find { |fk| fk.column == column }&.to_table
        ids = deleted_ids_by_table.fetch(target_table, [])
        return if ids.empty?

        @connection.execute(<<~SQL.squish)
          UPDATE #{@connection.quote_table_name(table)}
          SET #{@connection.quote_column_name(column)} = NULL
          WHERE #{@connection.quote_column_name(column)} IN (#{sql_id_list(ids)})
        SQL
      end

      def merge_layers(layers)
        merged = Hash.new { |hash, key| hash[key] = Set.new }
        layers.each { |layer| layer.each { |table, ids| merged[table].merge(ids) } }
        merged
      end

      def delete_layers(layers)
        ids_by_table = merge_layers(layers)
        deletion_order(ids_by_table.keys).each do |table|
          ids = ids_by_table[table]
          next if ids.empty?

          @connection.execute(<<~SQL.squish)
            DELETE FROM #{@connection.quote_table_name(table)}
            WHERE id IN (#{sql_id_list(ids)})
          SQL
        end
      end

      def deletion_order(tables)
        included = tables.to_set
        visited = Set.new
        ([@root_table] + tables).flat_map { |table| dependency_order(table, included, visited) }
      end

      def dependency_order(table, included, visited)
        return [] unless visited.add?(table)

        children = self.class.reverse_restrict_graph.fetch(table, []).filter_map do |edge|
          edge[:table] if included.include?(edge[:table])
        end
        children.flat_map { |child| dependency_order(child, included, visited) } << table
      end

      def sql_id_list(ids)
        ids.to_a.map { |id| Integer(id) }.join(",")
      end
    end
  end
end
