const client = require('prom-client')
const express = require('express')

const collectDefaultMetrics = client.collectDefaultMetrics
// collect every 5 seconds
collectDefaultMetrics({ timeout: 5000 })


const app = express()

// home
app.get('/', (req, res) => {

  res.send(`<a href="/counter" target="_blank">counter</a><br/>
    <a href="/push" target="_blank">push</a><br/>
    <a href="/pop" target="_blank">pop</a><br/>
    <a href="/wait" target="_blank">wait</a><br/>
    <a href="/metrics" target="_blank">metrics</a>`)
})

// 
// Counter
// 

const _counter = new client.Counter({
  name: 'request_count',
  help: 'Number of requests.'
})

app.get('/counter', (req, res) => {
  _counter.inc()
  res.send(`<b>${_counter.name}</b> increased`)
})

// 
// Gauge
// 

const _queue = new client.Gauge({
  name: 'queue_size',
  help: 'The size of the queue.'
})

app.get('/push', (req, res) => {
  _queue.inc()
  res.send(`<b>${_queue.name}</b> increased`)
})

app.get('/pop', (req, res) => {
  _queue.dec()
  res.send(`<b>${_queue.name}</b> decreased`)
})

// 
// Histogram
// 

const _histogram = new client.Histogram({
  name: 'request_duration',
  help: 'Time for HTTP request.',
  // buckets: [1, 2, 5, 6, 10]
})

app.get('/wait', (req, res) => {
  var max
  var rnd = Math.random()
  if (rnd < .4) { max = 1 } 
  else if (rnd < .8) { max = 3 } 
  else max = 10

  const ms = Math.floor(Math.random() * max * 1000)
  setTimeout(function () {
    // convert to seconds
    _histogram.observe(ms / 1000)
    res.send(`<b>${_histogram.name}_bucket</b> filled.<br/>
              <b>${_histogram.name}_sum</b> computed.<br/>
              <b>${_histogram.name}_count</b> increased.<br/>
              I kept you waiting for ${ms} ms!`)
  }, ms)
})


// metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType)
  res.end(await client.register.metrics())
})


const PORT = 5000
app.listen(PORT, () => {
  console.log(`Listening port : ${PORT}`)
})
