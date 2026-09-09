require "rails_helper"

RSpec.describe "Public website routing", type: :routing do
  it "routes the public and private landing pages explicitly" do
    expect(get: "/").to route_to(controller: "public/home", action: "show")
    expect(get: "/ar").to route_to(controller: "public/home", action: "show", locale: "ar")
    expect(get: "/en").to route_to(controller: "public/home", action: "show", locale: "en")
    expect(get: "/dashboard").to route_to(controller: "dashboard", action: "index")
  end

  it "routes the public catalog pages per locale using slugs" do
    expect(get: "/ar/programs").to route_to(controller: "public/programs", action: "index", locale: "ar")
    expect(get: "/en/programs").to route_to(controller: "public/programs", action: "index", locale: "en")
    expect(public_program_path(locale: :ar, slug: "أساسيات-القرآن"))
      .to eq("/ar/programs/#{ERB::Util.url_encode('أساسيات-القرآن')}")
    expect(get: "/en/programs/quran-foundations")
      .to route_to(controller: "public/programs", action: "show", locale: "en", slug: "quran-foundations")
    expect(get: "/ar/fees").to route_to(controller: "public/fees", action: "index", locale: "ar")
    expect(get: "/en/fees").to route_to(controller: "public/fees", action: "index", locale: "en")
  end

  it "does not expose public catalog pages outside the supported locales" do
    expect(get: "/fr/programs").not_to be_routable
    expect(get: "/programs").not_to be_routable
    expect(get: "/fees").not_to be_routable
    expect(get: "/en/course_offerings").not_to be_routable
  end

  it "does not treat unsupported locale prefixes as public homepages" do
    expect(get: "/fr").not_to be_routable
  end
end
