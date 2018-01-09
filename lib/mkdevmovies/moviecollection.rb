require 'open-uri'
require 'csv'
require 'dotenv'
require_relative 'movie'
require_relative 'cache'

module Mkdevmovies
  class MovieCollection
    include Enumerable
    attr_reader :movies, :cache
    DATA_STRUCTURE = %i[link title r_year country r_date genres runtime rating director actors].freeze

    def initialize
      @cache = Cache.new(ENV['FILE_CACHE_YAML'])
      file = File.open(ENV['FILE_RECORD_TXT']).read
      @movies = CSV.parse(file, col_sep: '|', headers: DATA_STRUCTURE)
                   .map { |movie_fixture| Movie.create(movie_fixture.to_hash, self) }
    end

    def all
      @movies
    end

    def sort_by(sort_key)
      if sort_key == :director
        @movies.sort_by { |x| x.director.split.last }
      else
        @movies.sort_by { |x| x.send(sort_key) }
      end
    end

    def filter(**filters)
      movies = @movies.select do |movie|
        filters.all? do |field, filter_key|
          if field.to_s.include?('exclude')
            !movie.matches?(field.to_s.split('exclude_').last.to_sym, filter_key)
          else
            movie.matches?(field, filter_key)
          end
        end
      end
      movies.empty? ? (raise 'Wrong filter options.') : movies
    end

    def stats(field)
      @movies.flat_map { |obj| obj.send(field) }
             .compact
             .each_with_object(Hash.new(0)) { |obj, stats| stats[obj] += 1 }
    end

    def genres
      @movies.flat_map(&:genres).uniq
    end

    def by_genre
      @by_genre ||= Genres.new(self)
    end

    def by_country
      @by_country ||= Countrys.new(self)
    end

    def each(&block)
      @movies.each(&block)
    end

    class Genres
      def initialize(collection)
        collection.genres.each do |name|
          self.class.send(:define_method, name.downcase) do
            collection.filter(genres: name)
          end
        end
      end
    end
    class Countrys
      def initialize(collection)
        @collection = collection
      end

      def method_missing(country_name)
        @collection.filter(country: Regexp.new(country_name.to_s.tr('_', ' '), 'i'))
      end
    end
  end
end