const puppeteer = require('puppeteer');
var myArgs = process.argv.slice(2);

(async () => {
	const browser = await puppeteer.launch({
	headless: true,
	args: ['--no-sandbox'] });
	const page = await browser.newPage();
	await page.setViewport({
		  width: 1680,
		  height: 925,
		  deviceScaleFactor: 2,
		});
	await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0').catch((err) => {});
	await page.goto(myArgs[0]).catch((err) => {});
	await page.addScriptTag({url: 'https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js'}).catch((err) => {console.log(err);});
	await page.evaluate(() => {
		try {
		    	var allDivs = $('div div');
			var topZindex = 5000;
			var targetRoles = ["dialog","modal","alert","alertdialog"];
			var targetClasses = ["dialog","modal","alert","alertdialog", "message", "survey"];
			allDivs.each(function(){
				try{
					var currentZindex = parseInt($(this).css('z-index'), 10);
					if(currentZindex > topZindex) {
						$(this).hide();
						return true;
					}
					if(targetRoles.includes($(this).attr("role"))) {
						$(this).hide();
						return true;
					}
					var classList = $(this).attr('class').split(/\s+/);
					  for (var i = 0; i < classList.length; i++) {
					    	for (var j = 0; j < targetClasses.length; j++) {
						    if (classList[i].includes(targetClasses[j])) {
							$(this).hide();
							return true;
						    }
						}
					  }
				}catch(fail){}
			});
		} catch(err) {}
	    }).catch((err) => {console.log(err);});
	await page.screenshot({path: '/root/site.png'}).catch((err) => {});
	await browser.close().catch((err) => {});
})();
