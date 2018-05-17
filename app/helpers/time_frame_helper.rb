class TimeFrameHelper

    def self.all
      return [:one_hour, :one_day, :one_week, :one_month]
    end

    def self.to_seconds(enum_item)
        case enum_item
        when "one_hour"
            return 1.hour
        when "one_day"
            return 1.day
        when "one_week"
            return 1.week
        else
            return 1.month
        end
    end
end