pavlov.specify("Omega.Pages.Stats", function(){
describe("Omega.Pages.Stats", function(){
  var page;

  before(function(){
    page = new Omega.Pages.Stats();
  });

  /// base page mixin test
  it("has a node", function(){
    assert(page.node).isOfType(Omega.Node);
  });
});});
