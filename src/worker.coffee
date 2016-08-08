Request = require 'superagent'
Async = require 'async'
Cluster = require 'cluster'
Path = require 'path'
Os = require 'os'
Fs = require 'fs'
Express = require 'express'
{Config, Jobs, Validator} = require 'docr-common'

log = require('easylog')(module)

class WorkerServer

	taskWorkers: {}

	startTaskWorkers : (done) ->
		Async.each Config.worker.enabled, (taskWorkerName, doneTaskWorker) =>
			@taskWorkers[taskWorkerName] = taskWorker = \
				new (require "./task/#{taskWorkerName}")(Config)
			taskWorker.installed 
			nrProcesses = Config.worker.available[taskWorkerName]?.concurrent || 1
			Jobs.process taskWorkerName, nrProcesses, (data, doneTask) ->
				processOpts = {}
				# TODO setup working directory
				processOpts.cwd = 'TODO'
				# TODO download input files (data.input) from blob server
				taskWorker.process cwd, data, (err, result) ->
					return doneTask err if err
					# TODO save output (result) to blob server and store in data
					return doneTask null, data
			doneTaskWorker()
		, done

	startExpress : (done) ->
		@app = new Express()
		@app.listen Config.worker.port, ->
			log.info "Worker #{process.pid} listening on #{Config.worker.port}"
			done()

	start: (done) ->
		@startTaskWorkers =>
			# TODO handle errors
			@startExpress done

	constructor: (Config) ->

Cluster.on 'online', (worker) ->
	log.info "Worker process #{worker.process.pid} is online"
	return
Cluster.on 'exit', (worker, code, signal) ->
	log.info "Worker process #{worker.process.pid} died with code #{code} and signal #{signal}. Restarting"
	Cluster.fork()
	return

if Cluster.isMaster
	log.info "Starting cluster"
	log.debug "Config:", Config
	for i in [0 ... Config.worker.cluster_size]
		Cluster.fork()
else
	server = new WorkerServer()
	server.start ->
		log.info "Started worker server #{process.pid}"
