var allDivs = $('div div');
var topZindex = 100;
allDivs.each(function(){
    var currentZindex = parseInt($(this).css('z-index'), 10);
    if(currentZindex > topZindex) {
        $(this).css('z-index',-1)
    }
});
