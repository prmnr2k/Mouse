class EventUpdate < ApplicationRecord
    enum action: HistoryHelper::EVENT_ACTIONS, _suffix: true
    enum field: HistoryHelper::EVENT_FIELDS, _suffix: true

    belongs_to :event
end
