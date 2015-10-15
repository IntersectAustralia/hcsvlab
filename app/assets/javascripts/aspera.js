var asperaWeb;
var asperaInstaller;
var asperaConnected;

function isAsperaConnected() {
    return asperaConnected === true;
}

function checkAsperaConnectInstalled(callback) {
    var CONNECT_INSTALLER = '//d3gcli72yxqn2z.cloudfront.net/connect/v4';
    var ASPERA_MIN_VERSION = '3.6.0';

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
                if (callback !== undefined) {
                  callback.call();
                }
            }
        }
    };

    asperaWeb.addEventListener(AW4.Connect.EVENT.STATUS, statusEventListener);
    asperaWeb.initSession();
}

function performAsperaDownloadTransferForItemList(id, regexp) {
    console.log("perform aspera download transfer for item list: ", id);

    function flashAlert(message, type) {
        $('#flash-container').empty();
        $('#flash-container').append("<div class=\"alert alert-" + type + " fade in\"><a class=\"close\" data-dimiss=\"alert\">x</a>" + message + "</div>");
    }

    function reportError(message, error) {
        console.log(message, ':', error);
        flashAlert(message, 'error');
    }

    function reportMessage(message) {
        console.log(message);
        flashAlert(message, 'success');
    }

    function executeDownloadTransfer(transferSpec, connectSpec) {
        console.log("execute download transfer");

        asperaWeb.startTransfer(transferSpec, connectSpec, {
            success: function() {
                console.log("transfer started");
            },
            error: function(error) {
                reportError("Aspera connect transfer failed.", error)
            }
        });
    }

    function requestTransferSpec(directory) {
        console.log("request transfer spec");

        showProgressAnimation();

        $.post('/item_lists/' + id + '/aspera_transfer_spec?regexp=' + regexp, {}, undefined, 'json').done(function(data) {
            if (data['transfer_spec'] !== undefined) {
                var transferSpec = data['transfer_spec'];
                transferSpec['destination_root'] = directory;
                console.log("transfer spec:", transferSpec);

                connectSpec = {
                    // use absolute path to destionation directory e.g. /home/[user]/data/...
                    use_absolute_destination_path: true
                }
                console.log("connect spec:", connectSpec);

                executeDownloadTransfer(transferSpec, connectSpec);
            } else if (data['message'] !== undefined) {
                reportMessage(data['message']);
            }
        }).fail(function(object, type, message) {
            reportError("Error found while trying to request aspera download.", message);
        }).always(function() {
            hideProgressAnimation();
        });
    }

    function selectDownloadDirectory() {
        console.log("select download directory");

        asperaWeb.showSelectFolderDialog({
            success: function(object) {
                files = object['dataTransfer']['files'];
                if (files.length > 0) {
                    directory = files[0]['name'];
                    console.log("download directory:", directory);

                    requestTransferSpec(directory);
                } else {
                     console.log("no download directory selected");
                }
            },
            error: function(error) {
                reportError("Error found trying to select download directory.", error);
            }
        });
    }

    if (isAsperaConnected()) {
        selectDownloadDirectory();
    } else {
      checkAsperaConnectInstalled(function() {
          selectDownloadDirectory();
      });
    }
}

