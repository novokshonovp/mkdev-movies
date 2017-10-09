require 'zip'
require 'csv'
require 'ostruct'
require 'date'

DATA_STRUCTURE = %i[link title r_year country r_date genres runtime rating director actors]

class MovieCollection < Movie
  attr_reader :movies
  def initialize(filename_zip, filename_txt)
    zip_file = Zip::File.new(DEFS[:filename_zip]).read(DEFS[:filename_txt])
    @movies = CSV.parse(zip_file,:col_sep=>"|",:headers=>DATA_STRUCTURE).map{ |i| Movie.new(OpenStruct.new(i.to_h),self) }
  end
  def all
    @movies
  end
  def sort_by(sort_key)
    if sort_key == :director
       @movies.sort_by {|x| x.director.split.last}
    else
       @movies.sort_by {|x| x.send(sort_key) }   
    end    
  end
  
  def filter(**filter_keys)
      @movies.select {|movie|  filter_keys.all? { | value , key | movie.has_key?(value,key)} }
  end
  
  def stats(stat_key)
      @movies.flat_map {|obj| obj.send(stat_key)}
                    .compact
                    .each_with_object(Hash.new(0)){ |obj,stats|  stats[obj] += 1  }
  end
end