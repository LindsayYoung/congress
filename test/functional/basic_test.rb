require './test/test_helper'

class BasicTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include TestHelper::Methods

  def test_status
    get "/"
    assert_response 200
    assert_json

    assert_match /report_bugs/, last_response.body
  end

  def test_mongo
    bill = Bill.create!(
      bill_id: "hr1492-113",
      short_title: "Columbus Sailed the Ocean Blue"
    )

    get "/bills", {bill_id: "hr1492-113"}
    assert_response 200
    assert_json

    assert_match /Columbus Sailed/, last_response.body
  end

  def test_elasticsearch
    Utils.es_store! "bills", "hr1492-113", {
      bill_id: "hr1492-113",
      short_title: "Columbus Sailed the Ocean Blue"
    }
    Searchable.client.indices.refresh

    get "/bills/search", {bill_id: "hr1492-113"}
    assert_response 200
    assert_json

    assert_match /Columbus Sailed/, last_response.body
  end

  def test_elasticsearch_custom_score
    Utils.es_store! "bills", "hr1492-113", {
      bill_id: "hr1492-113",
      short_title: "Columbus Sailed the Ocean Blue",

      # this search profile needs this field, or it'll error
      introduced_on: "2014-03-01"
    }
    Searchable.client.indices.refresh

    get "/bills/search", {
      bill_id: "hr1492-113",
      query: "sailed",
      "search.profile" => "title_summary_recency"
    }

    assert_response 200
    assert_json

    assert_match /Columbus Sailed/, last_response.body
  end

end