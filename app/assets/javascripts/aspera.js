var CONNECT_INSTALLER = '//d3gcli72yxqn2z.cloudfront.net/connect/v4';
var ASPERA_MIN_VERSION = '3.6.0';

var asperaWeb;
var asperaInstaller;
var asperaConnected;

function connectOrInstallAsperaPlugin(connectCallback) {
  asperaWeb = new AW4.Connect({
    sdkLocation: CONNECT_INSTALLER,
    minVersion: ASPERA_MIN_VERSION
  });

  asperaInstaller = new AW4.ConnectInstaller({
    sdkLocation: CONNECT_INSTALLER
  });

  var statusEventListener = function(eventType, data) {
    var status = AW4.Connect.STATUS;
    if (eventType === AW4.Connect.EVENT.STATUS) {
      if (data === status.INITIALIZING) {
        asperaInstaller.showLaunching();
      }
      if (data === status.FAILED) {
        asperaInstaller.showDownload();
      }
      if (data === status.OUTDATED) {
        asperaInstaller.showUpdate();
      }
      if (data === status.RUNNING) {
        asperaInstaller.connected();
        asperaConnected = true;
        if (connectCallback !== undefined) {
          connectCallback.call();
        }
      }
    }
  };

  asperaWeb.addEventListener(AW4.Connect.EVENT.STATUS, statusEventListener);
  asperaWeb.initSession();
}

function isAsperaConnected() {
  return asperaConnected === true;
}

function requestTransferSpecForItemList(id) {
  console.log("request transfer spec for item list " + id);
  alert("Connect Plugin working succesfully");
}

function performAsperaDownloadForItemList(id) {
  if (isAsperaConnected()) {
    requestTransferSpecForItemList(id);
  } else {
    connectOrInstallAsperaPlugin(function() {
      console.log("aspera connected");
      requestTransferSpecForItemList(id);
    });
  }
}
