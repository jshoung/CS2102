const express = require('express')
const { body, validationResult } = require('express-validator/check')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
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

let config = {
  connectionString: process.env.DATABASE_URL,
  ssl: true,
}
if (process.env.NODE_ENV !== 'production') {
  const env = require('./env')
  config = {
    user: env.DBuser,
    host: 'localhost',
    database: env.DBname,
    password: env.DBpassword,
    port: 5432,
  }
}
const pool = new Pool(config)

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
app.get('/users', async (req, res) => {
  const data = await pool.query('select * from useraccount')

  res.send({ data })
})

app.post('/users/items', [body('userId').isInt()], async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  const { rowCount } = await pool.query(
    'select userId from UserAccount where userId = $1',
    [req.body.userId],
  )
  if (!rowCount) {
    return res.status(404).json({ errors: 'User not found in the database' })
  }
  let data = await pool.query('select * from LoanerItem where userID = $1', [
    req.body.userId,
  ])

  res.send({ data })
})

app.post('/add-item', async (req, res) => {
  await pool.query(
    'insert into loaneritem (itemname, value, itemdescription, userid) values ($1, $2, $3, $4)',
    [req.body.itemName, req.body.itemValue, req.body.itemDesc, req.body.userId],
  )
  res.send(200)
})

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
