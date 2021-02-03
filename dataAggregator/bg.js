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
	await page.setDefaultNavigationTimeout(0); 
	await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0');

	await page.goto(myArgs[0]);
	await page.screenshot({path: '/root/site.png'});
	await browser.close();
})();
