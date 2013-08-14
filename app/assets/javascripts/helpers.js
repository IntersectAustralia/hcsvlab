function showWarning(message) {
	showMessage(message, 'warning');
}

function showNotification(message) {
	showMessage(message, null);
}

function showMessage(message, classToUse) {
	var options = { message: message };
	if (classToUse != null) options.useClass = classToUse;
	$.bar(options);
}

function toggleItemList(main) {
	checks = document.getElementsByClassName('toggle_item_list');
	for (var i=0, n=checks.length; i<n; i++) {
		checks[i].checked = main.checked;
	}
}

function toggleCollection(main) {
    checks = document.getElementsByClassName('toggle_collection');
    for (var i=0, n=checks.length; i<n; i++) {
        checks[i].checked = main.checked;
    }
}