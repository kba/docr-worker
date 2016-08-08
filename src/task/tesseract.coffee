Which = require 'which'

module.exports = \
class Tesseract

	constructor: (@config) ->

	installed : (done) -> Which 'tesseract', done

	process: (cwd, data) ->
