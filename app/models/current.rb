class Current < ActiveSupport::CurrentAttributes
  attribute :user, :change_reason
end
