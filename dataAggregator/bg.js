const puppeteer = require('puppeteer');
var myArgs = process.argv.slice(2);
if (myArgs[0].search(/http.*\/\//) == -1)
	myArgs[0] = "http://" + myArgs[0];

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
	await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0').catch((err) => {console.log(err);});
	await page.goto(myArgs[0], {waitUntil: 'networkidle2'}).catch((err) => {console.log(err);});
	await page.waitForNavigation({waitUntil: 'networkidle2'}).catch((err) => {});
	await page.evaluate(async () => {
            var script = document.createElement('script');
            script.src = "https://code.jquery.com/jquery-3.5.1.min.js";
            document.getElementsByTagName('head')[0].appendChild(script);

            while (!window.jQuery)
                await new Promise(r => setTimeout(r, 500));
        }).catch((err) => {
            console.log(err);
        });

	await page.evaluate(() => {
		try {
			var allDivs = $('div');
			var topZindex = 10000;
			var targetRoles = ["dialog","modal","alert","alertdialog"];
			var targetClasses = ["dialog","modal","alert","alertdialog", "survey", "hidden"];
			allDivs.each(function(){
				$(this).find(":hidden").remove();
			});
			allDivs = $('div');
			allDivs.each(function(){
				try{
					var currentZindex = parseInt($(this).css('z-index'), 10);
					if(currentZindex > topZindex) {
						$(this).remove();
						return true;
					}
					if(targetRoles.includes($(this).attr("role"))) {
						$(this).remove();
						return true;
					}
					var classList = $(this).attr('class').split(/\s+/);
					for (var i = 0; i < classList.length; i++) {
						for (var j = 0; j < targetClasses.length; j++) {
						    if (classList[i].includes(targetClasses[j])) {
							$(this).remove();
							return true;
						    }
						}
					}
				}catch(err){console.log(err);}
			});
		} catch(err) {}
	    }).catch((err) => {console.log(err);});
	
	await page.screenshot({path: '/root/site.png'}).catch((err) => {});
	await browser.close().catch((err) => {});
})();
