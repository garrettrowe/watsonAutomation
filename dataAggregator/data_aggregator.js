var Crawler = require("simplecrawler");
const puppeteer = require('puppeteer-extra')
const StealthPlugin = require('puppeteer-extra-plugin-stealth')
puppeteer.use(StealthPlugin())
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
crawler.supportedMimeTypes = [/^text\/html/i];
crawler.interval = 5000;
crawler.maxConcurrency = 1;
crawler.listenerTTL = 120000;
crawler.allowedProtocols[/^http(s)?$/i];

var gettingPage = false

function hashCode(str) {
    var hash = 0,
        i, chr;
    for (i = 0; i < str.length; i++) {
        chr = str.charCodeAt(i);
        hash = ((hash << 5) - hash) + chr;
        hash |= 0;
    }
    return hash;
}

crawler.on("fetchstart", async function(queueItem, responseBuffer, response) {
    cont = this.wait();
    queueItem.url = queueItem.url.trim();
    console.log("Evaluating: " + queueItem.url);
    if (gettingPage) {
        console.log("too soon, back to queue: " + queueItem.url);
        crawler.queue.update(queueItem.id, {
            fetched: false,
            status: "queued"
        },function(error, queueItem) {
            if (error) {
                return crawler.emit("queueerror", error, queueItem);
            }
        });
        return;
    }
    var qii = queueItem.url.replace(/\?.*/,"");

    var ea = [".js"];
    var eb = [".pdf", ".xml", ".rss", ".doc", ".xls", ".ppt", ".jpg", ".png", ".gif", ".ico", ".bmp", ".svg", ".mp3", ".wav", ".css"];
    var ec = [".woff", ".json", ".woff2"];
    if (!ea.includes(qii.slice(-3).toLowerCase()) && !eb.includes(qii.slice(-4).toLowerCase()) && !ec.includes(qii.slice(-5).toLowerCase())) {
        console.log("doing fetch: " + queueItem.url);
        gettingPage = true;
        await getPandL(queueItem.url);
        gettingPage = false;
        cont();
        crawler.queue.update(queueItem.id, {
            fetched: true,
            status: "downloaded"
        }, function(error, queueItem) {
            crawler._openRequests.splice(0, 1);
            if (error) {
                return crawler.emit("queueerror", error, queueItem);
            }
            crawler.emit("fetchcomplete", queueItem, "", response);
        });
        return;
    }else {
        crawler.queue.update(queueItem.id, {
            fetched: true,
            status: "downloaded"
        }, function(error, queueItem) {
            crawler._openRequests.splice(0, 1);
            if (error) {
                return crawler.emit("queueerror", error, queueItem);
            }
            crawler.emit("fetchcomplete", queueItem, "", response);
        });
    }
});

crawler.on("complete", function() {
    console.log("Queue Complete");
    crawler.queueURL(myArgs[0]);
    setInterval(function() {
        crawler.queue.countItems({
            status: "queued"
        }, function(error, items) {
            if (items)
                crawler.start();
        });
    }, 5000);
    setTimeout(function() {
        crawler.queue.countItems({
            status: "queued"
        }, function(error, items) {
            console.log("Final Check: " + items);
            if (items)
                crawler.start();
            else
                otp = true;
        });
    }, 240000);
});


async function launchBrowser() {
    try {
        const browser = await puppeteer.launch({
            headless: true,
            args: ['--no-sandbox', '--proxy-server=http://compound.latentsolutions.com:18888']
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
        return page;
    } catch (e) {
        console.log(e);
    }
}

function getOTP() {
    return new Promise(function(resolve, reject) {
        (function waitForOTP() {
            if (otp) return resolve(otp);
            setTimeout(waitForOTP, 30);
        })();
    });
}


async function getPandL(url) {
    let links = [];
    try {
        console.log("processing: " + url);
        let page = await getPage().catch((err) => {
            console.log(err);
        });
        
        const maxRetryNumber = 10;
        for (let retryNumber = 1; retryNumber <= maxRetryNumber; retryNumber++) {
            const response = await page.goto(url, {waitUntil: 'networkidle2'}).catch((err) => {console.log(err);});
            if (response) {
                if (response.status() < 400) {
                    break;
                }
            }
            await new Promise(r => setTimeout(r, 5000));
        }

        await page.evaluate(async () => {
            var script = document.createElement('script');
            script.src = "https://code.jquery.com/jquery-3.5.1.min.js";
            document.getElementsByTagName('head')[0].appendChild(script);

            while (!window.jQuery)
                await new Promise(r => setTimeout(r, 500));
        }).catch((err) => {
            console.log(err);
        });

        links = await page.$$eval('a', links => links.map(a => a.href)).catch((err) => {
            console.log(err);
        });

        links.forEach(function(item, index) {
            crawler.queueURL(item);
        });
        console.log("added: " + links.length + ", queue length: " + crawler.queue.length + " at " + url);

        await page.evaluate(() => {
            try {
                var allDivs = $('div');
                var topZindex = 5000;
                var targetRoles = ["modal", "alert", "alertdialog"];
                var targetClasses = ["modal", "alert", "alertdialog", "survey", "hidden"];
                allDivs.each(function() {
                    $(this).find(":hidden").remove();
                });
                allDivs = $('div');
                allDivs.each(function() {
                    try {
                        var currentZindex = parseInt($(this).css('z-index'), 10);
                        if (currentZindex > topZindex) {
                            $(this).remove();
                            return true;
                        }
                        if (targetRoles.includes($(this).attr("role"))) {
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
                    } catch (fail) {}
                });
            } catch (err) {}
        }).catch((err) => {
            console.log(err);
        });


        let pageTitle = await page.title().catch((err) => {
            console.error(err);
        });
        pageTitle = pageTitle.replace(/[-_|\#\@\!\%\^\&\*\(\)\<\>\[\]\{\}]+/gi, " ");
        let pname = url.replace(/http.*\/\//, "").replace(/(\?|#).*/,"").replace(/\/$/, "");


        const data = JSON.parse(fs.readFileSync('/root/nlu.txt', 'utf8'));

        let phtml = await page.content().catch((err) => {
            console.error(err);
        });
        phtml = phtml.replace(/<head([\S\s]*?)>([\S\s]*?)<\/head>/gi, "");
        phtml = phtml.replace(/<style([\S\s]*?)>([\S\s]*?)<\/style>/gi, "");
        phtml = phtml.replace(/<script([\S\s]*?)>([\S\s]*?)<\/script>/gi, "");
        phtml = phtml.replace(/<li([\S\s]*?)>([\S\s]*?)<\/li>/gi, "");
        phtml = phtml.replace(/<ul([\S\s]*?)>([\S\s]*?)<\/ul>/gi, "");
        phtml = phtml.replace(/<nav([\S\s]*?)>([\S\s]*?)<\/nav>/gi, "");
        phtml = phtml.replace(/<a ([\S\s]*?)>([\S\s]*?)<\/a>/gi, "");
        phtml = phtml.replace(/<!--([\S\s]*?)-->/gi, "");

        let summarizeitems = [];
        summarizeitems.push(phtml);
        summarizeitems.push(phtml.match(/<section([\S\s]*?)>([\S\s]*?)<\/section>/gi));

        for (var i = 0; i < summarizeitems.length; i++) {
            console.log(pname + " part " + i);
            if (summarizeitems[i]) {
                iterate += 1;
                console.log(url + " doc length: " + summarizeitems[i].length);
                let header = {
                    "Content-type": "application/json",
                    "authorization": "Basic " + Buffer.from("apikey:" + data.apikey).toString("base64")
                };
                let bod = {
                    "html": summarizeitems[i],
                    "features": {
                        "summarization": {
                            "limit": 8
                        }
                    }
                };
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

                (async function(outJSON, pname, iterate, options) {
                    try {
                        request(options, function(error, response, body) {
                            try {
                                if (!error && response.statusCode == 200) {
                                    let out = body;
                                    outJSON.text = out.summarization.text;

                                    let ojsH = hashCode(outJSON.text);
                                    if (!outitems.includes(ojsH)) {
                                        outitems.push(ojsH);
                                        fse.outputFileSync("/root/da/crawl/" + pname + iterate + ".json", JSON.stringify(outJSON));
                                        console.log("wrote " + pname + iterate + ".json");
                                        return;
                                    } else {
                                        console.log("Dupe hash, skipping " + pname);
                                        return;
                                    }
                                } else {
                                    console.log("Error calling NLU on: " + pname + " : " + JSON.stringify(body));
                                    return;
                                }
                            } catch (err) {
                                console.error(err);
                                return;
                            }
                        });
                    } catch (err) {
                        console.error(err);
                    }
                })(outJSON, pname, iterate, options);
            } else {
                console.log("Empty Doc, skipping " + url);
            }
        }

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
        return;
    } catch (err) {
        console.log("getPandL error:" + err);
    }
}

async function main() {
    try {
        let browser = await launchBrowser().catch((err) => {
            console.error(err);
        });
        console.log("start: ");
        crawler.start();
        const ans = await getOTP().catch((err) => {
            console.error(err);
        });
        if (browser)
            await browser.close().catch((err) => {
                console.error(err);
            });
    } catch (e) {
        console.log(e);
    } finally {
        console.log("done: ");
        process.exit();
    }
}

main();
