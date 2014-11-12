class Postcode
  include Mongoid::Document
  include Mongoid::Timestamps

  field :postcode, type: String
  field :area, type: String
  field :outcode, type: String
  field :incode, type: String
  field :easting, type: Integer
  field :northing, type: Integer
  field :introduced, type: Date
  field :terminated, type: Date
  field :authority, type: String
  
end