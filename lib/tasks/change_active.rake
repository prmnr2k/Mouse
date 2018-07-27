namespace :events do
  desc "Change active status"
  task change_artist_number: :environment do
    events = Event.joins(:artist_events).where(status: "active")
    puts "Going to update #{events.count} events"

    ActiveRecord::Base.transaction do
      events.each do |event|
        event.artist_events.status = "owner_accepted"
        event.save!
        print "."
      end
    end

    events = Event.joins(:venue_events).where(status: "active")
    puts "Going to update #{events.count} events"

    ActiveRecord::Base.transaction do
      events.each do |event|
        event.venue_events.status = "owner_accepted"
        event.save!
        print "."
      end
    end

    puts " All done now!"
  end
end