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
	await page.addScriptTag({url: 'https://code.jquery.com/jquery-3.2.1.min.js'}).catch((err) => {});
	await page.addScriptTag({url: 'https://raw.githubusercontent.com/garrettrowe/watsonAutomation/main/dataAggregator/popBreaker.js'}).catch((err) => {});
	await page.waitForNavigation({waitUntil: 'networkidle2'}).catch((err) => {});
	await page.screenshot({path: '/root/site.png'}).catch((err) => {});
	await browser.close().catch((err) => {});
})();
