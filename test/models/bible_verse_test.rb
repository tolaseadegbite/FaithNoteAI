# == Schema Information
#
# Table name: bible_verses
#
#  id          :bigint           not null, primary key
#  book        :string           not null
#  chapter     :integer          not null
#  content     :text             not null
#  language    :string           default("en"), not null
#  translation :string           default("KJV"), not null
#  verse       :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bible_verses_on_reference_and_translation  (book,chapter,verse,translation,language) UNIQUE
#
require "test_helper"

class BibleVerseTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
