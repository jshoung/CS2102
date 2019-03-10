const express = require('express')
const { body, validationResult } = require('express-validator/check')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
const env = require('./env')
const cors = require('cors')

const logRequestStart = (req, res, next) => {
  console.info(`${req.method} ${req.originalUrl}`)

  res.on('finish', () => {
    console.info(
      `${res.statusCode} ${res.statusMessage}; ${res.get('Content-Length') ||
        0}b sent`,
    )
  })

  next()
}

const pool = new Pool({
  user: env.DBuser,
  host: 'localhost',
  database: env.DBname,
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
app.use(logRequestStart)
app.use(cors())

/* This endpoint gets all the users currently in the database
   Might need to specify parameters in req if we want to do filtering
*/
app.post('/users', async (req, res) => {
  const client = await pool.connect()
  let data
  data = await client.query('select * from useraccount')

  res.send({ data: data })
})

app.post('/users/items', [body('userId').isInt()], async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }
  const body = req.body
  const client = await pool.connect()
  const { rowCount } = await client.query(
    'select userId from UserAccount where userId = $1',
    [req.body.userId],
  )
  if (!rowCount) {
    return res.status(404).json({ errors: 'User not found in the database' })
  }
  let data = await client.query('select * from LoanerItem where userID = $1', [
    req.body.userId,
  ])

  res.send({ data: data })
})

app.post('/api/world', (req, res) => {
  console.log(req.body)
  res.send(`This is what you sent me: ${req.body.post}`)
})

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
