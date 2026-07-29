module Admin
  class UsersQuery
    SORTS = {
      "name" => "LOWER(users.first_name) %<direction>s, LOWER(users.last_name) %<direction>s",
      "email" => "LOWER(users.email) %<direction>s",
      "role" => "users.role %<direction>s",
      "status" => "users.status %<direction>s",
      "created_at" => "users.created_at %<direction>s",
      "last_sign_in_at" => "users.last_sign_in_at %<direction>s NULLS LAST"
    }.freeze

    def initialize(scope: User.all, params: {})
      @scope = scope
      @params = params
    end

    def call
      filtered = search(@scope)
      filtered = enum_filter(filtered, :role)
      filtered = enum_filter(filtered, :status)
      filtered = locale_filter(filtered)
      filtered.order(Arel.sql(order_clause))
    end

    private

    def search(scope)
      term = @params[:query].to_s.strip
      return scope if term.blank?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
      scope.where(
        "users.first_name ILIKE :pattern OR users.last_name ILIKE :pattern " \
        "OR users.email ILIKE :pattern OR CONCAT_WS(' ', users.first_name, users.last_name) ILIKE :pattern",
        pattern:
      )
    end

    def enum_filter(scope, name)
      value = @params[name].to_s
      values = User.public_send(name.to_s.pluralize)
      value.in?(values.keys) ? scope.where(name => values.fetch(value)) : scope
    end

    def locale_filter(scope)
      locale = @params[:preferred_locale].to_s
      locale.in?(%w[ar en]) ? scope.where(preferred_locale: locale) : scope
    end

    def order_clause
      sort = SORTS.key?(@params[:sort].to_s) ? @params[:sort].to_s : "created_at"
      direction = @params[:direction].to_s == "asc" ? "ASC" : "DESC"
      "#{format(SORTS.fetch(sort), direction:)} , users.id #{direction}"
    end
  end
end
