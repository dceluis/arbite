class Coin < ApplicationRecord
  belongs_to :market

  validates_presence_of :name
  validates_presence_of :fee
  validates_presence_of :confirmations
end
