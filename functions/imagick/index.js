const { sentryHandler } = require('./sentry');
const tmpdl = require('./tmpdl');
const fs = require('fs');
const im = require('imagickal');
const FileType = require('file-type');

// const https = require('https');
// const fs = require('fs');
// const temp = require('temp');

const actionsMap = {
  link_thumbnail(req) {
    return {
      trim: true,
      resize: {
        width: req.body.width,
        height: req.body.height,
      },
      gravity: true,
      center: true,
    };
  },
  // actions: {
  //   resize: { width: 100 },
  //   crop: { width: 10, height: 10, x: 10, y: 10 },
  //   quality: 90,
  //   strip: true,
  // },
};

exports.fn = sentryHandler(async (req, res) => {
  if (req.method !== 'POST') return res.send('');
  if (!actionsMap[req.body.action]) return res.send('');
  console.log('imagick.from_url:', req.body.from_url);
  console.log('imagick.body:', req.body);
  const unlinks = [];
  try {
    const tmpfilename = await tmpdl(req.body.from_url);
    const tmpfilename2 = `${tmpfilename}2`;
    unlinks.push(tmpfilename);
    unlinks.push(tmpfilename2);

    console.log('imagick.transform:', tmpfilename, tmpfilename2, req.body.action, actionsMap[req.body.action](req));
    await im.transform(tmpfilename, tmpfilename2, actionsMap[req.body.action](req));
    // console.log('imagick:', {transformResult});
    // res.send(JSON.stringify({ message: 'Ok', result: null }));
    // console.log('typeof readFileSync:', typeof fs.readFileSync(tmpfilename2));

    const fileType = await FileType.fromFile(tmpfilename2)
    console.log({fileType});


    res.set('Content-Type', fileType.mime);
    res.send(fs.readFileSync(tmpfilename2));
  } finally {
    for (let i = unlinks.length - 1; i >= 0; i--) {
      await new Promise(resolve => fs.unlink(unlinks[i], resolve));
    }
  }
});
