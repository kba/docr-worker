Cluster = require 'cluster'
Path = require 'path'
Os = require 'os'
Fs = require 'fs'
CONFIG = require('js-yaml').safeLoad(Fs.readFileSync(Path.join(__dirname, '../config.yml')))
Express = require 'express'

log = require('easylog')(module)

Cluster.on 'online', (worker) ->
	log.info "Worker #{worker.process.pid} is online"
	return

Cluster.on 'exit', (worker, code, signal) ->
	log.info "Worker #{worker.process.pid} died with code #{code} and signal #{signal}. Restarting"
	Cluster.fork()
	return

if Cluster.isMaster
	log.info "Starting cluster"
	log.debug "Config:", CONFIG
	for i in [0 .. Os.cpus().length]
		Cluster.fork()
else
	app = new Express()
	app.all '/', (req, res) ->
		res.send "Hi from #{process.pid}!"
		process.exit()
	app.listen CONFIG.port, ->
		log.info "Worker #{process.pid} listening on #{CONFIG.port}"
