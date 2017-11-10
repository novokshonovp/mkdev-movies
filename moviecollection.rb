require 'zip'
require 'csv'
require 'ostruct'
require_relative 'movie'

class MovieCollection 
  include Enumerable 
  DATA_STRUCTURE = %i[link title r_year country r_date genres runtime rating director actors]
  attr_reader :movies
  
  def initialize(filename_zip, filename_txt)
    zip_file = Zip::File.new(filename_zip).read(filename_txt)
    @movies = CSV.parse(zip_file,:col_sep=>"|",:headers=>DATA_STRUCTURE).map{ |i| 
                      Movie::create(OpenStruct.new(i.to_h),self)}
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
  
  def filter(**filters)
      movies = @movies.select {|movie|  filters.all? { | field , filter_key | movie.matches?(field,filter_key)} }
      raise "Wrong filter options. No movie in the database!" if movies.empty?
      movies
  end 
  def stats(field)
      @movies.flat_map {|obj| obj.send(field)}
                    .compact
                    .each_with_object(Hash.new(0)){ |obj,stats|  stats[obj] += 1  }
  end
  
  def genres
    @movies.flat_map{|field| field.genres }.uniq
  end
  
  def each(&block)
    @movies.each(&block)
  end
end