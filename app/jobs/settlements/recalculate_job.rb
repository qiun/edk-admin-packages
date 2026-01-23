module Settlements
  class RecalculateJob < ApplicationJob
    queue_as :default

    def perform(user, edition)
      Settlements::Calculator.new(user, edition).call
    end
  end
end
