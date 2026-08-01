module Admin
  class AccountInvitationsQuery
    SORTS = { "created" => "account_invitations.created_at", "expires" => "expires_at",
              "accepted" => "accepted_at" }.freeze

    def initialize(params:, relation: AccountInvitation.all)
      @params = params
      @relation = relation
    end

    def call
      scope = @relation.includes(:user, :created_by)
      scope = scope.where(status: @params[:status]) if AccountInvitation::STATUSES.include?(@params[:status])
      scope = search(scope)
      column = SORTS.fetch(@params[:sort], "account_invitations.created_at")
      direction = @params[:direction] == "asc" ? :asc : :desc
      scope.order(Arel.sql("#{column} #{direction == :asc ? 'ASC' : 'DESC'}"), id: :desc)
    end

    private

    def search(scope)
      return scope if @params[:query].blank?

      term = "%#{ActiveRecord::Base.sanitize_sql_like(@params[:query].strip)}%"
      scope.joins(:user).where("users.first_name ILIKE :term OR users.last_name ILIKE :term OR " \
                               "users.email ILIKE :term OR users.role::text ILIKE :term", term:)
    end
  end
end
