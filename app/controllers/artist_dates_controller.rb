class ArtistDatesController

  swagger_api :create do
    param :form, :available_dates, :string, :optional, "Artist available dates [{'begin_date': '', 'end_date': ''}, {...}]"
  end
  def create

  end

  private

  def set_artist_dates
    if params[:available_dates]
      @artist.available_dates.clear
      params[:available_dates].each do |date_range|
        obj = ArtistDate.new(artist_dates_params(date_range))
        obj.save
        @artist.available_dates << obj
      end
      @artist.save
    end
  end

  def artist_dates_params(date)
    date.permit(:begin_date, :end_date)
  end
end