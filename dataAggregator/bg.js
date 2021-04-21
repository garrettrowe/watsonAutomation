const puppeteer = require('puppeteer-extra')
const StealthPlugin = require('puppeteer-extra-plugin-stealth')
puppeteer.use(StealthPlugin())

var myArgs = process.argv.slice(2);
if (myArgs[0].search(/http.*\/\//) == -1)
	myArgs[0] = "http://" + myArgs[0];

(async () => {

	const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox']
        });
	const page = await browser.newPage();
	await page.setViewport({
		  width: 1680,
		  height: 925,
		  deviceScaleFactor: 2,
		});
	page.setDefaultNavigationTimeout(120000);
	
	const maxRetryNumber = 10;
	for (let retryNumber = 1; retryNumber <= maxRetryNumber; retryNumber++) {
		const response = await page.goto(myArgs[0], {waitUntil: 'networkidle2'}).catch((err) => {console.log(err);});
		if (response) {
			if (response.status() < 400) {
			    break;
			}
		    }
		await new Promise(r => setTimeout(r, 5000));
	}

	await page.evaluate(() => {
            var script = document.createElement('script');
            script.src = "https://code.jquery.com/jquery-3.5.1.min.js";
            document.getElementsByTagName('head')[0].appendChild(script);

        }).catch((err) => {
            console.log(err);
        });
    await page.waitForNavigation({timeout: 5000}).catch((err) => {});

	await page.evaluate(() => {
		try {
			var allDivs = $('div');
			var topZindex = 10000;
			var targetRoles = ["modal","alert","alertdialog"];
			var targetClasses = ["modal","alert","alertdialog", "survey"];
			
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
				}catch(err){console.log(err);}
			});
		} catch(err) {}
	    }).catch((err) => {console.log(err);});
	
	await page.screenshot({path: '/root/site.png'}).catch((err) => {});
	await browser.close().catch((err) => {});
})();
