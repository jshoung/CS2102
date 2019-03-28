const express = require('express')
const { body, validationResult } = require('express-validator/check')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
const cors = require('cors')
const hash = require('object-hash')

const { checkInvoicedLoanSchema } = require('./middleware')

const app = express()
const port = process.env.PORT || 5000

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
  const data = await pool.query('select * from useraccount')

  res.send({ data })
})

// ******************* //
//        Items        //
// ******************* //

app.post('/users/items', [body('userId').isInt()], async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  // Check whether user exists in database
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

// *************************** //
//        Invoiced Loans       //
// *************************** //

app.post('/users/loans/create', checkInvoicedLoanSchema, async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  let data
  try {
    data = await pool.query(
      `insert into InvoicedLoan (invoiceID, startDate, endDate, penalty, loanFee, loanerID, borrowerID, itemID) 
      values ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        req.body.invoiceID,
        req.body.startDate,
        req.body.endDate,
        req.body.penalty,
        req.body.loanFee,
        req.body.loanerID,
        req.body.borrowerID,
        req.body.itemID,
      ],
    )
  } catch (error) {
    return res.status(400).json({ errors: error })
  }

  res.send({ data })
})

app.post('/users/loans/update', checkInvoicedLoanSchema, async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  // Check whether InvoicedLoan exists in database
  const { rowCount } = await pool.query(
    'select invoiceID from InvoicedLoan where invoiceID = $1',
    [req.body.invoiceID],
  )
  if (!rowCount) {
    return res
      .status(404)
      .json({ errors: 'InvoicedLoan not found in the database' })
  }

  let data
  try {
    data = await pool.query(
      `update InvoicedLoan set 
        startDate = $2, endDate = $3, penalty = $4, loanFee = $5, loanerID = $6, borrowerID = $7, itemID = $8
          where invoiceID = $1`,
      [
        req.body.invoiceID,
        req.body.startDate,
        req.body.endDate,
        req.body.penalty,
        req.body.loanFee,
        req.body.loanerID,
        req.body.borrowerID,
        req.body.itemID,
      ],
    )
  } catch (error) {
    return res.status(400).json({ errors: error })
  }

  res.send({ data })
})

app.post(
  '/users/loans/delete',
  [body('invoiceID').isInt()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }

    // Check whether InvoicedLoan exists in database
    const { rowCount } = await pool.query(
      'select invoiceID from InvoicedLoan where invoiceID = $1',
      [req.body.invoiceID],
    )
    if (!rowCount) {
      return res
        .status(404)
        .json({ errors: 'InvoicedLoan not found in the database' })
    }

    let data
    try {
      data = await pool.query(
        `delete from InvoicedLoan  
          where invoiceID = $1`,
        [req.body.invoiceID],
      )
    } catch (error) {
      return res.status(400).json({ errors: error })
    }

    res.send({ data })
  },
)

app.post('/users/loans', [body('userId').isInt()], async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }
  const body = req.body

  let data = await pool.query(
    `select startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID
      from InvoicedLoan IL
        where IL.loanerID = $1 or IL.borrowerID = $1`,
    [req.body.userId],
  )

  res.send({ data })
})

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
