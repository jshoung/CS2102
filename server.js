const express = require('express')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
const env = require('./env')

const pool = new Pool({
  user: env.DBuser,
  host: 'localhost',
  database: 'CarouShare',
  password: env.DBpassword,
  port: 5432,
})

const app = express()
const port = process.env.PORT || 5000

app.use(compression())
app.use(helmet())
app.use(morgan('combined'))
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))
app.use(express.static(path.join(__dirname, 'client/build')))

app.get('/api/hello', (req, res) => {
  res.send({ data: { title: 'Hello World', description: 'We share stuff.' } })
})

app.post('/api/world', (req, res) => {
  console.log(req.body)
  res.send(`This is what you sent me: ${req.body.post}`)
})

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
