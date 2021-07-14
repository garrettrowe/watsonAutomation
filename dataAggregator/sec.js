const puppeteer = require('puppeteer-extra')
const StealthPlugin = require('puppeteer-extra-plugin-stealth')
puppeteer.use(StealthPlugin())
let browser = null;
var myArgs = process.argv.slice(2);
if (myArgs[0].search(/http.*\/\//) == -1)
        myArgs[0] = "http://" + myArgs[0];

let width = 2560
let height = 1600

async function launchBrowser() {
    try {
        const browser = await puppeteer.launch({
            executablePath: '/usr/bin/google-chrome',
            headless: true,
            defaultViewport: { width, height },
            ignoreHTTPSErrors: true,
            args: [   '--no-sandbox', 
                      '--ignore-certificate-errors', 
                      '--disable-features=IsolateOrigins,site-per-process', 
                      '--flag-switches-begin --disable-site-isolation-trials --flag-switches-end',
                      '--disable-accelerated-2d-canvas',
                      '--disable-blink-features=AutomationControlled',
                      '--disable-dev-shm-usage',
                      '--disable-gpu',
                      '--disable-setuid-sandbox',
                      '--disable-web-security',
                      '--ignore-certificate-errors',
                      '--no-first-run',
                      '--window-size=2560,1600'
                  ]
        });
        return browser;
    } catch (e) {
        console.log(e);
    }
}

async function launchHBrowser() {
    try {
        const browser = await puppeteer.launch({
            executablePath: '/usr/bin/google-chrome',
            headless: true,
            defaultViewport: { width, height },
	    ignoreHTTPSErrors: true,
	    args: [   myArgs[1],
		      '--no-sandbox', 
		      '--ignore-certificate-errors', 
		      '--disable-features=IsolateOrigins,site-per-process', 
		      '--flag-switches-begin --disable-site-isolation-trials --flag-switches-end',
		      '--disable-accelerated-2d-canvas',
		      '--disable-blink-features=AutomationControlled',
		      '--disable-dev-shm-usage',
		      '--disable-gpu',
		      '--disable-setuid-sandbox',
		      '--disable-web-security',
		      '--ignore-certificate-errors',
		      '--no-first-run',
		      '--window-size=2560,1600'
		  ]
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
            const response = await page.goto(myArgs[0], {waitUntil: 'networkidle0'}).catch((err) => {console.log(err);});
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
            }else{
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
            await new Promise(r => setTimeout(r, 5000));
        }
    try{
        var i = 1;
        while(true){
            console.log("printing " + i)
            await page.pdf({
                pageRanges: i.toString(),
                path: '/root/10k/10k_page' + i + '.pdf',
                format: 'letter',
                printBackground: false
              });
            i = i+1;
        }
    }catch(fail){
    }
	await browser.close().catch((err) => {});
})();
