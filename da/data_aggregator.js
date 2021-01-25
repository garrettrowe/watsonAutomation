var Crawler = require("simplecrawler");
const puppeteer = require('puppeteer');
const fse = require('fs-extra');
var myArgs = process.argv.slice(2);
var iterate = 0;
var uitems = [];

	
var crawler = new Crawler(myArgs[0]);
crawler.maxDepth = 2;
crawler.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0";
crawler.respectRobotsTxt = 0;
crawler.allowInitialDomainChange = 1;
crawler.scanSubdomains = 1;

crawler.downloadUnsupported = 0;
crawler.supportedMimeTypes = ["text/html", "text/html;charset=UTF-8","text/html; charset=UTF-8"];
crawler.on("fetchcomplete", function(queueItem, responseBuffer, response) {
	uitems.push(queueItem.url);
});
crawler.on("complete", function(queueItem){
    evaluatel(myArgs[0]);
});
crawler.start();


async function evaluatel(murl){
	var browser =  await puppeteer.launch({
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

	for await (let i of uitems) {
		var lurl = i;
		var next = 0;
		while(next == 0){
			try {
				await page.goto(lurl, {waitUntil: 'networkidle2'});
				var pageTitle = await page.evaluate(async(lurl) => {
					let pageTitle = await page.title();
					pageTitle = pageTitle.replace(/[-_|\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi," ");
					return pageTitle;
				});
				let pname = lurl.split("/");
				pname = pname[pname.length-1];
				if(!pname || 0 === pname.length){
						pname = "index";
				}
				pname = pname.replace(/[- |\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi,"_");
				await page.screenshot({path:"/root/demo/" + pname + ".png"});
				let sel = "div";
				const text = await page.evaluate(async(sel, pname, pageTitle) => {
					let elements = Array.from(document.querySelectorAll(sel));
					let links = elements.map(element => {
						return element.parentElement.innerHTML;
					});
					for (let j of links) {
						iterate +=1;
						var out = j.replace(/<html([\S\s]*?)>([\S\s]*?)<\/html>/gi, "");
						var out = j.replace(/<head([\S\s]*?)>([\S\s]*?)<\/head>/gi, "");
						var out = j.replace(/<body([\S\s]*?)>([\S\s]*?)<\/body>/gi, "");
						var out = j.replace(/<style([\S\s]*?)>([\S\s]*?)<\/style>/gi, "");
						var out = out.replace(/<script([\S\s]*?)>([\S\s]*?)<\/script>/gi, "");
						var out = "<div><p>" + out.replace(/<.\w*[^>]*>/gi, "</p></div><div><p>")+ "</p></div>";
						var out = out.replace(/(<div><p>) *(<\/p><\/div>)/gi, "");
						var out = out.replace(/( )+/gi, " ");
						var out = out.replace(/([\t\n])+/gi, "</p></div><div><p>");
						var out = out.replace(/(<div><p>) *(<\/p><\/div>)/gi, "");
						var out = "<html><head><title>" + pageTitle + "</title></head><body>" + out + "</body></html>";
						if (out.length > 400)
							await fse.outputFile("/root/da/crawl/" + pname + "-" + iterate + ".html", out);
					}
				});
				
				next = 1;
			}catch (err) {
			    console.log("retry: " + lurl + "  error:" +err);
			}
		}
	}
	await browser.close();
	await fse.outputFile("/root/ready", "go");
}
