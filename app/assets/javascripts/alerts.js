$(window).load(function() {

    $(function () {
        var alert = $('.alert');
        if (alert.length > 0 && !alert.hasClass('permanent')) {
            alert.slideDown();

            alertTimeout = 9000;
            if (alert.hasClass('long-alert')) {
                alertTimeout = 20000;
            }
            var alerttimer = window.setTimeout(function() {
                alert.slideUp();
            }, alertTimeout);
            $(".alert").click(function () {
                window.clearTimeout(alerttimer);
                alert.slideUp();
            });
        }
    });

});

