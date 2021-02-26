var Crawler = require("simplecrawler");
const puppeteer = require('puppeteer');
const fse = require('fs-extra');
var myArgs = process.argv.slice(2);
var iterate = 0;
var uitems = [];
var outitems = [];
var browser = null;
var otp = null;
var cont = null;

process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0';
	
var crawler = new Crawler(myArgs[0]);
crawler.maxDepth = 4;
crawler.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0";
crawler.respectRobotsTxt = false;
crawler.allowInitialDomainChange = true;
crawler.scanSubdomains = true;
crawler.ignoreWWWDomain = true;
crawler.downloadUnsupported = false;
crawler.supportedMimeTypes = [];
crawler.interval = 1000; 
crawler.maxConcurrency = 1;
crawler.listenerTTL = 120000;
crawler.allowedProtocols ["http","https"];

var gettingPage = false

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

crawler.on("fetchstart", function(queueItem, responseBuffer, response) {
	cont = this.wait();
	if(gettingPage){
		queueItem.status = "queued";
		return;
	}
    console.log("doing fetch: " + queueItem.url);
	 getPandL(queueItem.url, cont).then(outp => {
	 		if(outp){
	            outp.forEach(function (item, index) {
	              crawler.queueURL(item);
	            });
	            console.log("added: " + outp.length + ", queue length: "+ crawler.queue.length);
	           }
	    }).catch((err) => {console.error(err); });   
});

crawler.on("complete", function () {
	setInterval(function(){ 
		crawler.queue.countItems({
		    status: "queued"
		}, function(error, items) {
		    if(items && !crawler.running)
		    	crawler.start();
		});
	}, 5000);
    setTimeout(function(){ 
    	crawler.queue.countItems({
		    status: "queued"
		}, function(error, items) {
			console.log("Final Check: " + items);
		    if(items && !crawler.running)
		    	crawler.start();
		    else
		    	otp = true;
		});
    }, 240000);   
});


async function launchBrowser(){
	try {
		const browser = await puppeteer.launch({
		headless: true,
		userDataDir: '/root/da',
		args: ['--no-sandbox'] });
		return browser;
	}catch (e) {
		console.log(e);
	}
}

async function getPage(){
	try {
		if(!browser)
			browser = await launchBrowser().catch((err) => {console.error(err); });
		const page = await browser.newPage();
		await page.setViewport({
			  width: 1680,
			  height: 925,
			  deviceScaleFactor: 2,
			});
		await page.setDefaultNavigationTimeout(8000); 
		await page.setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0");
		return page;
	}catch (e) {
		console.log(e);
	}
}

function getOTP() {
    return new Promise(function (resolve, reject) {
        (function waitForOTP(){
            if (otp) return resolve(otp);
            setTimeout(waitForOTP, 30);
        })();
    });
}

async function setGettingPage(gp) {
    gettingPage = gp;
}


async function getPandL(url, cont, gettingPage){
	try {
			await setGettingPage(true).catch((err) => {});
			console.log("processing: " + url);
    		let page = await getPage(browser).catch((err) => {console.log(err); });
			await page.goto(url, {waitUntil: 'networkidle0'}).catch((err) => {});
			
			let pageTitle = await page.title().catch((err) => {});
			pageTitle = pageTitle.replace(/[-_|\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi," ");
			let pname = url.split("/");
			pname = pname[pname.length-1];
			if(!pname || 0 === pname.length){
					pname = "index";
			}
			pname = pname.replace(/[- |\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi,"_");
			var sel = "div";
			var links = await page.evaluate((sel) => {
				let elements = Array.from(document.querySelectorAll(sel));
				let links = elements.map(element => {
				    return element.parentElement.innerHTML;
				})
				return links;
			    }, sel).catch((err) => {});
			for (let j of links) {
				iterate +=1;
				var out = j.replace(/<html([\S\s]*?)>([\S\s]*?)<\/html>/gi, "");
				var out = out.replace(/<head([\S\s]*?)>([\S\s]*?)<\/head>/gi, "");
				var out = out.replace(/<body([\S\s]*?)>([\S\s]*?)<\/body>/gi, "");
				var out = out.replace(/<style([\S\s]*?)>([\S\s]*?)<\/style>/gi, "");
				var out = out.replace(/<script([\S\s]*?)>([\S\s]*?)<\/script>/gi, "");
				var out = out.replace(/<!--([\S\s]*?)-->/gi, "");
				var out = out.replace(/&[a-z]+;/g, "");
				var out = "." + out.replace(/<.\w*[^>]*>/gi, ".").trim();
				var out = out.replace(/\.[\w \\/]{0,80}(?=\.)/gi, ".");
				var out = out.replace(/( )+/gi, " ");
				var out = out.replace(/([\t\n])+/gi, ".");
				var out = out.replace(/\..{0,60}\./gi, ".");
				var out = out.replace(/\. */gi, ".");
				var out = out.replace(/\.+/gi, ".");
				var out = out.replace(/\.+/gi, ". ");
				var out = out.replace(/^\. */, "");
			
				let outJSON = { 
				    title: pageTitle,
				    text: out, 
				    source_link: url
				};
				if (out.length > 150){
					let ojs = JSON.stringify(outJSON);
					let ojsH = hashCode(ojs);
					if (!outitems.includes(ojsH)){
						outitems.push(ojsH)
						fse.outputFileSync("/root/da/crawl/" + pname + "-" + iterate + ".json", ojs);
					}
				}
			}

			 sel = "a[href]";
			 links = await page.evaluate((sel) => {
				let elements = Array.from(document.querySelectorAll(sel));
				let links = elements.map(element => {
				    return element.getAttribute('href');
				})
				return links;
			    }, sel).catch((err) => {});
			console.log("got: " + links.length + " at " + url);

			if(page)
				await page.close().catch((err) => {console.log(err); });
			return links;
		}catch (err) {
		    console.log("error:" +err);
		}finally{
			await setGettingPage(false).catch((err) => {});
			cont();
		}

}

function hashCode(str) {
  var hash = 0, i, chr;
  for (i = 0; i < str.length; i++) {
    chr   = str.charCodeAt(i);
    hash  = ((hash << 5) - hash) + chr;
    hash |= 0; 
  }
  return hash;
}

async function main(){
	try {
		let browser = await launchBrowser().catch((err) => {console.error(err); });
		console.log("start: ");
		crawler.start();
		const ans = await getOTP().catch((err) => {console.error(err); });
		if(browser)
    		await browser.close().catch((err) => {console.error(err); });
		} catch (e) {
      	console.log(e);
    }finally {
    	console.log("done: ");
    	process.exit();
    }
}

main();
