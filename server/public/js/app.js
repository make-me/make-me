// make_me weblication
window.MakeMe = function MakeMe(){};
window.thingiurlbase = "/js";

MakeMe.prototype.initSTL = function initSTL(){
  this.thingiview = new Thingiview("stl-viewer");
  this.thingiview.setObjectColor('#C0D8F0');
  this.thingiview.initScene();
  return this;
};

MakeMe.prototype.renderOctocat = function renderSTL() {
  if (!this.thingiview) this.initSTL()

  this.thingiview.loadSTL("/octocat-v1.5.stl");
  this.thingiview.setCameraView('side');
};

MakeMe.prototype.renderSTL = function renderSTL(stl_json) {
  if (!this.thingiview) this.initSTL()
  this.thingiview.loadSTL(stl_json); // is this right?
  this.thingiview.setCameraView('side');
};

window.app = new MakeMe();