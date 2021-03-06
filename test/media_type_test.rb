require_relative 'test_helper'

class MediaTypeTest < Minitest::Test
  M = Rack::AcceptHeaders::MediaType

  def test_qvalue
    m = M.new('text/html, text/*;q=0.3, */*;q=0.5')
    assert_equal(0.5, m.qvalue('image/png'))
    assert_equal(0.3, m.qvalue('text/plain'))
    assert_equal(1, m.qvalue('text/html'))

    m = M.new('text/html')
    assert_equal(0, m.qvalue('image/png'))

    m = M.new('')
    assert_equal(1, m.qvalue('text/html'))
  end

  def test_invalid_media_type
    assert_raises Rack::AcceptHeaders::Header::InvalidHeader do
      m = M.new('')
      m = M.new('text')
      m = M.new('text;q=1')
    end
  end

  def test_matches
    m = M.new('text/*, text/html, text/html;level=1, */*')
    assert_equal(%w{*/*}, m.matches(''))
    assert_equal(%w{*/*}, m.matches('image/jpeg'))
    assert_equal(%w{text/* */*}, m.matches('text/plain'))
    assert_equal(%w{text/html text/* */*}, m.matches('text/html'))
    assert_equal(%w{text/html text/* */*}, m.matches('text/html;level=1'))
    assert_equal(%w{text/html text/* */*}, m.matches('text/html;level=1;answer=42'))
  end

  def test_best_of
    m = M.new('text/*;q=0.5, text/html')
    assert_equal('text/html', m.best_of(%w< text/plain text/html >))
    assert_equal('text/plain', m.best_of(%w< text/plain image/png >))
    assert_equal('text/plain', m.best_of(%w< text/plain text/javascript >))
    assert_equal(nil, m.best_of(%w< image/png >))

    m = M.new('text/*')
    assert_equal('text/html', m.best_of(%w< text/html text/xml >))
    assert_equal('text/xml', m.best_of(%w< text/xml text/html >))

    m = M.new('TEXT/*')
    assert_equal('text/html', m.best_of(%w< text/html text/xml >))
    assert_equal('text/xml', m.best_of(%w< text/xml text/html >))
  end

  def test_extensions
    m = M.new('text/plain')
    assert_equal({'text/plain' => {'q' => '1'}}, m.extensions)
    m = M.new('text/*;q=0.5;a=42')
    assert_equal({'text/*' => {'q' => '0.5', 'a' => '42'}}, m.extensions)
  end

  def test_params
    m = M.new('text/plain;q=0.7;version=1.0')
    assert_equal({'q' => '0.7', 'version' => '1.0'}, m.params('text/plain'))
    m = M.new('text/*;q=0.5;a=42, application/json;b=12')
    assert_equal({'q' => '0.5', 'a' => '42'}, m.params('text/plain'))
    assert_equal({'q' => '1', 'b' => '12'}, m.params('application/json'))
  end

  def test_vendored_types
    m = M.new("application/vnd.ms-excel")
    assert_equal(nil, m.best_of(%w< application/vnd.ms-powerpoint >))

    m = M.new("application/vnd.api-v1+json")
    assert_equal(false, m.accept?("application/vnd.api-v2+json"))

    v1, v2 = "application/vnd.api-v1+json", "application/vnd.api-v2+json"
    m = M.new("#{v1},#{v2}")
    assert_equal(v1, m.best_of([v1, v2]))
    assert_equal(v2, m.best_of([v2, v1]))
  end
end
