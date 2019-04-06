const express = require('express')
const { query, body, validationResult } = require('express-validator/check')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
const cors = require('cors')

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

/*

ENDPOINTS

*/

// Users

app.get('/users', async (req, res) => {
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
  let data

  if (req.body.isListAvailable) {
    data = await pool.query(
      `select LI.itemId, LI.itemName, LI.value, LI.itemDescription, LI.userId, IL.invoiceId, UA.name as ownerName
                    from LoanerItem LI
                    left outer join 
                    InvoicedLoan IL
                    on LI.userID = IL.loanerID and LI.itemId = IL.itemID
                    left outer join
                    UserAccount UA
                    on UA.userId = LI.userId
                    where IL.invoiceID is NULL`,
    )
  } else {
    const { rowCount } = await pool.query(
      'select userId from UserAccount where userId = $1',
      [req.body.userId],
    )
    if (!rowCount) {
      return res.status(404).json({ errors: 'User not found in the database' })
    }
    data = await pool.query(
      `select LI.itemId, LI.itemName, LI.value, LI.itemDescription, LI.userId, IL.invoiceId, IL.startDate, IL.endDate, IL.penalty, IL.loanFee, IL.borrowerId, name as borrowerName
                    from LoanerItem LI
                    left outer join 
                    InvoicedLoan IL
                    on LI.userID = IL.loanerID and LI.itemId = IL.itemID
                    left outer join
                    UserAccount UA
                    on UA.userId = IL.borrowerId
                    where LI.userID = $1`,
      [req.body.userId],
    )
  }

  // Check whether user exists in database

  res.send({ data })
})

app.post('/add-item', async (req, res) => {
  await pool.query(
    'insert into loaneritem (itemname, value, itemdescription, userid) values ($1, $2, $3, $4)',
    [req.body.itemName, req.body.itemValue, req.body.itemDesc, req.body.userId],
  )
  res.sendStatus(200)
})

app.patch('/add-item', async (req, res) => {
  await pool.query(
    'update loaneritem set itemname = $1, value = $2, itemdescription = $3, userid = $4 where itemid = $5',
    [
      req.body.itemName,
      req.body.itemValue,
      req.body.itemDesc,
      req.body.userId,
      req.body.itemId,
    ],
  )
  res.sendStatus(200)
})

// *************************** //
//        Invoiced Loans       //
// *************************** //

app.post('/users/loans', checkInvoicedLoanSchema, async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }

  let data
  try {
    data = await pool.query(
      `insert into InvoicedLoan (startDate, endDate, penalty, loanFee, loanerID, borrowerID, itemID) 
      values ($1, $2, $3, $4, $5, $6, $7)`,
      [
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

app.patch('/users/loans', checkInvoicedLoanSchema, async (req, res) => {
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

app.delete('/users/loans', [body('invoiceID').isInt()], async (req, res) => {
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
})

app.get(
  '/users/loans',
  [query('userId').isInt(), query('isLoaner').isBoolean()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }

    let data

    // Getting InvoicedLoan object where userId = loanerID
    if (req.query.isLoaner === 'true') {
      data = await pool.query(
        `select startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID,itemName, value, itemDescription, name
        from (InvoicedLoan IL 
              natural join 
              LoanerItem)
              inner join UserAccount UA
              on IL.borrowerID = UA.userID
          where IL.loanerID = $1`,
        [req.query.userId],
      )
    } else {
      // Otherwise
      data = await pool.query(
        `select startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID,itemName, value, itemDescription,name
        from InvoicedLoan IL 
              natural join 
              LoanerItem
              inner join UserAccount UA
              on IL.loanerID = UA.userID
          where IL.borrowerID = $1`,
        [req.query.userId],
      )
    }

    res.send({ data })
  },
)

// *************************** //
//        Interest Groups      //
// *************************** //

app.get('/interestgroups', async (req, res) => {
  let data = await pool.query(
    `
    select groupName, groupDescription from InterestGroup
    `,
  )
  res.send({ data })
})

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
