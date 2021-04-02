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

var crawler = new Crawler(myArgs[0].replace(/^http:\/\//i, "https://"));
crawler.maxDepth = 4;
crawler.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0";
crawler.respectRobotsTxt = false;
crawler.allowInitialDomainChange = true;
crawler.scanSubdomains = true;
crawler.ignoreWWWDomain = false;
crawler.downloadUnsupported = false;
crawler.ignoreInvalidSSL = true;
crawler.supportedMimeTypes = [/^text\/html/i,];
crawler.interval = 1000; 
crawler.maxConcurrency = 1;
crawler.listenerTTL = 120000;
crawler.allowedProtocols [/^http(s)?$/i];

var gettingPage = false

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
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

crawler.on("fetchstart", function(queueItem, responseBuffer, response) {
	cont = this.wait();
	if(gettingPage){
		queueItem.status = "queued";
		return;
	}
    var excludefiles = [".pdf",".xml",".rss",".doc",".xml","ppt"];
    if (!excludefiles.includes(queueItem.url.slice(-4))) {
    	 console.log("doing fetch: " + queueItem.url);
		 getPandL(queueItem.url, cont).then(outp => {
		 		if(outp){
		            outp.forEach(function (item, index) {
		              crawler.queueURL(item);
		            });
		            console.log("added: " + outp.length + ", queue length: " + crawler.queue.length);
		           }
		    }).catch((err) => {console.error(err); });  
	   } 
});

crawler.on("complete", function () {
	crawler.queueURL(myArgs[0]);
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
	let links = [];
	try {
		await setGettingPage(true).catch((err) => {});
		console.log("processing: " + url);
    	let page = await getPage(browser).catch((err) => {console.log(err); });
		await page.goto(url, {waitUntil: 'networkidle2'}).catch((err) => {});
		await page.addScriptTag({url: 'https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js'}).catch((err) => {});
		
		links = await page.$$eval('a', links => links.map(a => a.href)).catch((err) => {console.log(err); });
		console.log("got: " + links.length + " at " + url);
		
		
		await page.evaluate(() => {
			try {
				var allDivs = $('div');
				var topZindex = 5000;
				var targetRoles = ["dialog","modal","alert","alertdialog"];
				var targetClasses = ["dialog","modal","alert","alertdialog", "message", "survey", "hidden"];
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
					}catch(fail){}
				});
			} catch(err) {}
		    }).catch((err) => {console.log(err);});
		

		let pageTitle = await page.title().catch((err) => {});
		pageTitle = pageTitle.replace(/[-_|\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi," ");
		let pname = url.replace(/http.*\/\//, "").replace(/\/$/, "");
		iterate +=1;

		const data = JSON.parse(fs.readFileSync('/root/nlu.txt', 'utf8'));

		let phtml = await page.evaluate(el => el.innerHTML, await page.$('body')).catch((err) => {});
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

		console.log("doc length: " + phtml.length);
		if (phtml.length){
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

					let ojsH = hashCode(outJSON.text);
					if (!outitems.includes(ojsH)){
						outitems.push(ojsH);
						fse.outputFileSync("/root/da/crawl/" + pname  + iterate + ".json", JSON.stringify(outJSON));
						console.log("wrote " + pname + iterate + ".json");
					} else{
						console.log("Dupe hash, skipping");
					}
				  }else{
					  console.log("Error calling NLU: " + JSON.stringify(response));
				  }
				});
			  })(outJSON, pname,iterate, options);
		 } else {
			 console.log("Empty Doc, skipping");
		 }

		if(page)
			await page.close().catch((err) => {});
		}catch (err) {
		    console.log("getPandL error:" +err);
		}finally{
			await setGettingPage(false).catch((err) => {});
			cont();
			return links;
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
