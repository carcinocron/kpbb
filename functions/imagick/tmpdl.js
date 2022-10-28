const { promisify } = require('util')
const download = require('download')
const path = require('path')
const tmp = require('tmp')
const { URL } = require('url')

const tmpNameAsync = promisify(tmp.tmpName)

/**
 * Exports
 */

module.exports = tmpdl

/**
 * Download a remote file to a temporary location
 *
 * @param   {string} src
 * @returns {Promise.<string>}
 */

async function tmpdl (src) {
  let tmpDir

  try {
    tmpDir = await tmpNameAsync()
  } catch (err) {
    throw new Error(err)
  }

  const filename = 'download'
  await download(src, tmpDir, { filename })

  const filepath = path.join(tmpDir, path.parse(filename).base)

  return filepath
}
