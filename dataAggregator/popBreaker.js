var allDivs = $('div div');
var topZindex = 5000;
var targetRoles = ["dialog","modal","alert","alertdialog"];
allDivs.each(function(){
    var currentZindex = parseInt($(this).css('z-index'), 10);
    if(currentZindex > topZindex) {
        $(this).hide();
        return true;
    }
    if(targetRoles.includes($(this).attr("role"))) {
        $(this).hide();
        return true;
    }
});
alert("hi");
