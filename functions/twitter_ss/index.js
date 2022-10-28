/**
 * this feature did not work reliably and is not in use. Not sure why.
 * I wanted to save twitter screenshots with light and dark mode versions.
 **/
require('regenerator-runtime/runtime');
const puppeteer = require('puppeteer');
const Sentry = require('@sentry/node')
if (process.env.APP_GOOGLE_CLOUD) {
  require('@google-cloud/debug-agent').start()
}
const fs = require('fs');
const temp = require('temp');
const webp = require('webp-converter');

Sentry.init({
  dsn: process.env.SENTRY_DSN
});

const TWEET_NOT_FOUND = /Page not found/
const JSON_TWEET_NOT_FOUND = { message: 'Tweet Not Found' }
exports.fn = sentryHandler(async (req, res) => {
  console.log('tweet_ss.url:', req.body.url);
  const tweetUrl = req.body.url;
  const lightFilePath = temp.path({suffix: '_light.png'});
  const darkFilePath = temp.path({suffix: '_dark.png'});
  // console.log('tweet_ss.lightFilePath:', lightFilePath);
  // console.log('tweet_ss.darkFilePath:', darkFilePath);

  let darkFilePromise = null;
  let lightFilePromise = null;

  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setViewport({
    width: 720,
    height: 1024,
    deviceScaleFactor: 1,
    isMobile: true,
  });
  await page.goto(tweetUrl, { waitUntil: 'networkidle0', timeout: 10000 });
  const tweetSelector = 'main section article[tabindex="0"][role="article"]';
  const timeout = parseInt(req.body.timeout || 5000);

  let page_title = await page.title();
  if (page_title.match(TWEET_NOT_FOUND)) {
    console.error('Tweet Not Found', {page_title});
    res.send(JSON.stringify(JSON_TWEET_NOT_FOUND));
    return;
  }
  console.log('page_title:', page_title)
  console.log('page_content:', (await page.content()))

  do {
    try {
      await page.waitFor(1);
      await page.waitForSelector(tweetSelector, {visible: true, timeout});
      const element = await page.$(tweetSelector);
      await element.screenshot({path: lightFilePath});
      lightFilePromise = toWebp(lightFilePath)
    } catch (err) {
      console.error(err.message);
      if ((err.message || '').includes('waiting for selector')) {
        console.log('page_title:', page_title = await page.title());
        console.log('page_content:', (await page.content()))
        if (page_title.match(TWEET_NOT_FOUND)) {
          console.error('Tweet Not Found', {page_title});
          res.send(JSON.stringify(JSON_TWEET_NOT_FOUND));
          return;
        }
      } else if (!puppeteerIgnoreErrors.includes(err.message)) {
        throw err;
      }
      console.error('unhandled error, retrying', err.message);
    }
  } while (lightFilePromise === null);
  await page.emulateMediaFeatures([{ name: 'prefers-color-scheme', value: 'dark' }]);
  do {
    try {
      await page.waitFor(1);
      await page.waitForSelector(tweetSelector, {visible: true, timeout});
      const element = await page.$(tweetSelector);
      await element.screenshot({path: darkFilePath});
      darkFilePromise = toWebp(darkFilePath)
    } catch (err) {
      console.error(err.message);
      console.log('page_title:', page_title = await page.title());
      console.log('page_content:', (await page.content()));
      if ((err.message || '').includes('waiting for selector')) {
        // pass
      } else if (!puppeteerIgnoreErrors.includes(err.message)) {
        throw err;
      }
      console.error('unhandled error, retrying', err.message);
    }
  } while (darkFilePromise === null);
  await browser.close();

  await Promise.all([lightFilePromise, darkFilePromise]).then(outfiles => {
    // console.log({ outfiles })
    const [lightFile, darkFile] = outfiles;
    // console.log(process.memoryUsage())
    res.send(JSON.stringify({ message: 'Ok', lightFile, darkFile }));
    // console.log(process.memoryUsage())
  })
});

function sentryHandler(lambdaHandler) {
  return async (...args) => {
    try {
      return await lambdaHandler(...args);
    } catch (error) {
      Sentry.captureException(error);
      await Sentry.flush(2000);
      throw error;
    }
  };
}

function toWebp(infilename) {
  return new Promise((resolve, reject) => {
    const outfilename = infilename.replace('.png', '.webp');
    webp.cwebp(infilename, outfilename, "", (status, error) => {
      //if conversion successful status will be '100'
      //if conversion fails status will be '101'
      console.log({status, error, outfilename});
      if (status === '100') {
        fs.readFile(outfilename, (err, data) => {
          console.log({outfilename});
          // console.log({err, data, outfilename});
          if (err) {
            reject(err);
          } else {
            resolve(data.toString());
          }
        });
        // resolve(outfilename);
      } else {
        reject(error);
      }
    });
  })
}

// we'll ignore these errors
// because it means we should wait longer
const puppeteerIgnoreErrors = [
  'Node is either not visible or not an HTMLElement',
];
