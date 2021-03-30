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
	await page.addScriptTag({url: 'https://code.jquery.com/jquery-3.2.1.min.js'}).catch((err) => {console.log(err);});
	await page.evaluate(() => {
		try {
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
		} catch(err) {}
	    }).catch((err) => {console.log(err);});
	await page.screenshot({path: '/root/site.png'}).catch((err) => {});
	await browser.close().catch((err) => {});
})();
