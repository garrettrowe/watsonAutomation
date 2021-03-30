var Crawler = require("simplecrawler");
const puppeteer = require('puppeteer');
var request = require('request');
const fs = require('fs');
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
			pname = pname.replace(/[- |\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi,"_").substring(0, 100);
			iterate +=1;

			const data = JSON.parse(fs.readFileSync('/root/nlu.txt', 'utf8'));

			let phtml = await page.evaluate(el => el.innerHTML, await page.$('body'));
			phtml = phtml.replace(/<head([\S\s]*?)>([\S\s]*?)<\/head>/gi, "");
			phtml = phtml.replace(/<style([\S\s]*?)>([\S\s]*?)<\/style>/gi, "");
			phtml = phtml.replace(/<link([\S\s]*?)>/gi, "");
			phtml = phtml.replace(/<script([\S\s]*?)>([\S\s]*?)<\/script>/gi, "");
			phtml = phtml.replace(/<iframe([\S\s]*?)>/gi, "");
			phtml = phtml.replace(/<\/iframe>/gi, "");
			phtml = phtml.replace(/<li([\S\s]*?)>([\S\s]*?)<\/li>/gi, "");
			phtml = phtml.replace(/<ul([\S\s]*?)>([\S\s]*?)<\/ul>/gi, "");
			phtml = phtml.replace(/<nav([\S\s]*?)>([\S\s]*?)<\/nav>/gi, "");
			phtml = phtml.replace(/<img([\S\s]*?)>/gi, "");
			phtml = phtml.replace(/<a ([\S\s]*?)>/gi, "");
			phtml = phtml.replace(/<\/a>/gi, "");
			phtml = phtml.replace(/<!--([\S\s]*?)-->/gi, "");

			let header = {"Content-type": "application/json", "authorization": "Basic " + Buffer.from("apikey:" + data.apikey).toString("base64") };
			let bod = {"html": phtml, "features": {"summarization": {"limit": 8 } } };
			let wurl = data.url + "/v1/analyze?version=2020-08-01";

			let outJSON = { 
				    title: pageTitle,
				    text: null, 
				    source_link: url
			};

			var options = {
			  uri: wurl,
			  headers: header,
			  method: 'POST',
			  json: bod
			};

			(function(outJSON, pname,iterate, options){
				request(options, function (error, response, body) {
				  if (!error && response.statusCode == 200) {
				    let out = body
				    outJSON.text = out.summarization.text;
					fse.outputFileSync("/root/da/crawl/" + pname + "-" + iterate + ".json", JSON.stringify(outJSON));
				  }
				});
			  })(outJSON, pname,iterate, options);

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
