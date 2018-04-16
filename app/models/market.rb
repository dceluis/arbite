class Market < ApplicationRecord
  has_many :coins

  validates_presence_of :name
end
