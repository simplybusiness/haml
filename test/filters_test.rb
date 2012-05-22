require 'test_helper'

class FiltersTest < MiniTest::Unit::TestCase
  test "should be registered as filters when including Haml::Filters::Base" do
    begin
      refute Haml::Filters.defined.has_key? "bar"
      Module.new {def self.name; "Foo::Bar"; end; include Haml::Filters::Base}
      assert Haml::Filters.defined.has_key? "bar"
    ensure
      Haml::Filters.defined.delete "bar"
    end
  end

  test "should raise error when attempting to register a defined Tilt filter" do
    begin
      assert_raises RuntimeError do
        2.times do
          Haml::Filters.register_tilt_filter "Foo"
        end
      end
    ensure
      Haml::Filters.defined.delete "foo"
    end
  end

  test "ERB filter with multiline expressions" do
    html = "foobarbaz\n"
    haml = %Q{:erb\n  <%= "foo" +\n      "bar" +\n      "baz" %>}
    assert_equal(html, render(haml))
  end

  test "should respect escaped newlines and interpolation" do
    html = "\\n\n"
    haml = ":plain\n  \\n\#{""}"
    assert_equal(html, render(haml))
  end

  test "should process an filter with no content" do
    assert_equal("\n", render(':plain'))
  end

  test "should be compatible with ugly mode" do
    expectation = "foo\n"
    assert_equal(expectation, render(":plain\n  foo", :ugly => true))
  end
end

class ErbFilterTest < MiniTest::Unit::TestCase
  test "should evaluate in the same context as Haml" do
    haml  = ":erb\n  <%= foo %>"
    html  = "bar\n"
    scope = Object.new.instance_eval {foo = "bar"; binding}
    assert_equal(html, render(haml, :scope => scope))
  end
end

class JavascriptFilterTest < MiniTest::Unit::TestCase
  test "should interpolate" do
    scope = Object.new.instance_eval {foo = "bar"; binding}
    haml  = ":javascript\n  \#{foo}"
    html  = render(haml, :scope => scope)
    assert_match(/bar/, html)
  end

  test "should never HTML-escape ampersands" do
    html = "<script type='text/javascript'>\n  //<![CDATA[\n    & < > &\n  //]]>\n</script>\n"
    haml = %Q{:javascript\n  & < > \#{"&"}}
    assert_equal(html, render(haml, :escape_html => true))
  end

  test "should not include type in HTML 5 output" do
    html = "<script>\n  //<![CDATA[\n    foo bar\n  //]]>\n</script>\n"
    haml = ":javascript\n  foo bar"
    assert_equal(html, render(haml, :format => :html5))
  end
end

class CSSFilterTest < MiniTest::Unit::TestCase
  test "should wrap output in CDATA and a CSS tag" do
    html = "<style type='text/css'>\n  /*<![CDATA[*/\n    foo\n  /*]]>*/\n</style>\n"
    haml = ":css\n  foo"
    assert_equal(html, render(haml))
  end

  test "should not include type in HTML 5 output" do
    html = "<style>\n  /*<![CDATA[*/\n    foo bar\n  /*]]>*/\n</style>\n"
    haml = ":css\n  foo bar"
    assert_equal(html, render(haml, :format => :html5))
  end
end

class CDATAFilterTest < MiniTest::Unit::TestCase
  test "should wrap output in CDATA tag" do
    html = "<![CDATA[\n    foo\n]]>\n"
    haml = ":cdata\n  foo"
    assert_equal(html, render(haml))
  end
end

class EscapedFilterTest < MiniTest::Unit::TestCase
  test "should escape ampersands" do
    html = "&amp;\n"
    haml = ":escaped\n  &"
    assert_equal(html, render(haml))
  end
end