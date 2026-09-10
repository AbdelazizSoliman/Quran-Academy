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
    expect(get: "/ar/faq").to route_to(controller: "public/faqs", action: "index", locale: "ar")
    expect(get: "/en/faq").to route_to(controller: "public/faqs", action: "index", locale: "en")
  end

  it "routes localized trial and contact submissions" do
    expect(get: "/ar/trial").to route_to(controller: "public/trial_requests", action: "new", locale: "ar")
    expect(post: "/en/trial").to route_to(controller: "public/trial_requests", action: "create", locale: "en")
    expect(get: "/ar/contact").to route_to(controller: "public/contact_requests", action: "new", locale: "ar")
    expect(post: "/en/contact").to route_to(controller: "public/contact_requests", action: "create", locale: "en")
  end

  it "does not expose public catalog pages outside the supported locales" do
    expect(get: "/fr/programs").not_to be_routable
    expect(get: "/programs").not_to be_routable
    expect(get: "/fees").not_to be_routable
    expect(get: "/trial").not_to be_routable
    expect(get: "/contact").not_to be_routable
    expect(get: "/faq").not_to be_routable
    expect(get: "/en/leads/1").not_to be_routable
    expect(get: "/en/course_offerings").not_to be_routable
  end

  it "does not treat unsupported locale prefixes as public homepages" do
    expect(get: "/fr").not_to be_routable
  end
end
