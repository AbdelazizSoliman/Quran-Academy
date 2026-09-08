require "rails_helper"

RSpec.describe "Public website routing", type: :routing do
  it "routes the public and private landing pages explicitly" do
    expect(get: "/").to route_to(controller: "public/home", action: "show")
    expect(get: "/ar").to route_to(controller: "public/home", action: "show", locale: "ar")
    expect(get: "/en").to route_to(controller: "public/home", action: "show", locale: "en")
    expect(get: "/dashboard").to route_to(controller: "dashboard", action: "index")
  end

  it "does not treat unsupported locale prefixes as public homepages" do
    expect(get: "/fr").not_to be_routable
  end
end
