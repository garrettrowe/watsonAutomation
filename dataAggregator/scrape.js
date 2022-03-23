const puppeteer = require('puppeteer');
const imageDataURI = require('image-data-uri');
const sharp = require('sharp');
const fs = require('fs');
var myArgs = process.argv.slice(2);
var backup = null;
var image = null;

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
  await page.setDefaultTimeout(4000);
  await page.setUserAgent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:78.0) Gecko/20100101 Firefox/78.0");
    await page.goto('https://www.google.com/search?q='+ myArgs[0].replace("_","+") +'+(company)');
    try {
      await page.waitForSelector('g-img.ivg-i');
      let element = await page.$('g-img.ivg-i');
      let value = await page.evaluate(el => el.innerHTML, element);
      value = value.match(/(data:image)[^"]*/)[0];
      await imageDataURI.outputFile(value, "/root/scrape/d" + myArgs[1] + ".png").then(res => console.log(res));
      await sharp("/root/scrape/d" + myArgs[1] + ".png")
          .resize(90, 90, {
            fit: 'inside'
          })
          .toFile("/root/scrape/d" + myArgs[1] + ".small.png");

        image = true;
    } catch (error) {
        //console.error(error);
        console.log("going to backup");
        backup = true;
    }
    try {
      
    } catch (error) {
     // console.error(error);
     console.log("going to backup");
      backup = true;
  }
  if(backup){
    try{
      if(!image){
        await page.goto('https://www.google.com/search?tbm=isch&q='+ myArgs[0].replace("_","+") +'+logo+(company)');
        await page.waitForSelector('#islrg');
        
        element = await page.$('#islrg');
        value = await page.evaluate(el => el.innerHTML, element).catch((err) => {console.error(err); });
        value = value.match(/(data:image)[^"]*/)[0];
        await imageDataURI.outputFile(value, "/root/scrape/d" + myArgs[1] + ".png").then(res => console.log(res));
        await sharp("/root/scrape/d" + myArgs[1] + ".png")
          .resize(90, 90, {
            fit: 'inside'
          })
          .toFile("/root/scrape/d" + myArgs[1] + ".small.png");
          
      }
    } catch (error) {
      console.error(error);
    }
  }
  await browser.close();
})();
