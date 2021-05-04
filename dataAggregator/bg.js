const puppeteer = require('puppeteer-extra')
const StealthPlugin = require('puppeteer-extra-plugin-stealth')
puppeteer.use(StealthPlugin())
let browser = null;
var myArgs = process.argv.slice(2);
if (myArgs[0].search(/http.*\/\//) == -1)
	myArgs[0] = "http://" + myArgs[0];

async function launchBrowser() {
    try {
        const browser = await puppeteer.launch({
            headless: true,
            args: ['--no-sandbox', '--ignore-certificate-errors']
        });
        return browser;
    } catch (e) {
        console.log(e);
    }
}
async function launchHBrowser() {
    try {
        const browser = await puppeteer.launch({
            headless: true,
            args: ['--no-sandbox', myArgs[1], '--ignore-certificate-errors']
        });
        return browser;
    } catch (e) {
        console.log(e);
    }
}
async function getPage() {
    try {
        if (!browser)
            browser = await launchBrowser().catch((err) => {
                console.error(err);
            });
        const page = await browser.newPage();
        page.setDefaultNavigationTimeout(120000);
	await page.setViewport({
		  width: 1680,
		  height: 925,
		  deviceScaleFactor: 2,
		});
        return page;
    } catch (e) {
        console.log(e);
    }
}


(async () => {

        let page = await getPage().catch((err) => {
            console.log(err);
        });
	
	const maxRetryNumber = 10;
        for (let retryNumber = 1; retryNumber <= maxRetryNumber; retryNumber++) {
            const response = await page.goto(myArgs[0], {waitUntil: 'networkidle2'}).catch((err) => {console.log(err);});
            if (response) {
                console.log("Response: " + response.status() );
                if (response.status() < 400) {
                    break;
                }
                if (retryNumber > 1 && response.status() == 403 ){
                    if (page)
                        await page.close().catch((err) => {
                            console.error(err);
                        });
                    if (browser) {
                        await browser.close().catch((err) => {
                            console.error(err);
                        });
                        browser = null;
                    }
                    browser = await launchHBrowser().catch((err) => {
                        console.error(err);
                    });
                    page = await getPage().catch((err) => {
                        console.log(err);
                    });
                }
            }
            await new Promise(r => setTimeout(r, 5000));
        }

	await page.evaluate(async () => {
            var script = document.createElement('script');
            script.src = "https://code.jquery.com/jquery-3.5.1.min.js";
            document.getElementsByTagName('head')[0].appendChild(script);
		
	    var retries = 0;

            while (!window.jQuery && retries < 20){
                retries += 1;
                await new Promise(r => setTimeout(r, 500));
            }
	    retries = 0;
	    while (!$ && retries < 10){
                retries += 1;
                await new Promise(r => setTimeout(r, 500));
            }

        }).catch((err) => {
            console.log(err);
        });

	await page.evaluate(() => {
		try {
			var allDivs = $('div');
			var topZindex = 10000;
			var targetRoles = ["modal","alert","alertdialog","tooltip"];
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
