const express = require('express')
const { query, body, validationResult } = require('express-validator/check')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
const cors = require('cors')
const moment = require('moment')

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

app.get('/users/loans', [body('userId').isInt()], async (req, res) => {
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

// *************************** //
//        Interest Groups      //
// *************************** //

app.get('/interestgroups', async (req, res) => {
  let data = await pool.query(
    `
    select IG.groupName, groupDescription, J.userId, J.joinDate
      from InterestGroup IG 
        left outer join
        Joins J
        on J.groupName = IG.groupName and J.userId = $1
        order by J.groupName
    `,
    [req.query.userId],
  )
  res.send({ data })
})

app.get(
  '/interestgroups/members',
  [query('groupName').isString()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    let data = await pool.query(
      `
      select J.userID, UA.name 
			from InterestGroup IG natural join Joins J natural join UserAccount UA
			where IG.groupName = $1;
    `,
      [req.query.groupName],
    )
    res.send({ data })
  },
)

app.get(
  '/users/interestgroups',
  [query('userId').isInt()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    let data = await pool.query(
      `
    select groupName, groupDescription, joinDate, groupAdminID, creationDate from 
      InterestGroup
      natural join 
      Joins
    where userId = $1
    `,
      [req.query.userId],
    )
    res.send({ data })
  },
)

app.post(
  '/interestgroups',
  [
    body('groupDescription').isString(),
    body('groupName').isString(),
    body('userId').isInt(),
  ],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    const currentDate = moment().format('MM-DD-YYYY')
    let data = await pool.query(
      `
      call insertNewInterestGroup($1, $2, $3, $4)
    `,
      [
        req.body.groupName,
        req.body.groupDescription,
        req.body.userId,
        currentDate,
      ],
    )
    res.send({ data })
  },
)

app.patch(
  '/interestgroups',
  [
    body('groupDescription').isString(),
    body('groupName').isString(),
    body('groupAdminId').isInt(),
    body('userId').isInt(),
  ],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }

    let data
    try {
      data = await pool.query(`call updateInterestGroup($1, $2, $3, $4)`, [
        req.body.userId,
        req.body.groupName,
        req.body.groupAdminId,
        req.body.groupDescription,
      ])
    } catch (error) {
      console.log('Error message:', error.hint)
      return res.status(400).json({ errors: error })
    }

    res.send({ data })
  },
)

app.delete(
  '/interestgroups',
  [query('groupName').isString()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    let data = await pool.query(
      `
      delete from InterestGroup where groupName = $1
    `,
      [req.query.groupName],
    )
    res.send({ data })
  },
)

// *************************** //
//            Joins            //
// *************************** //

app.delete(
  '/joins',
  [query('userId').isInt(), query('groupName').isString()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    let data

    try {
      data = await pool.query(
        `delete from Joins where userId = $1 and groupName = $2
      `,
        [req.query.userId, req.query.groupName],
      )
    } catch (error) {
      console.log('Error message:', error.hint)
      return res.status(400).json({ errors: error })
    }
    res.send({ data })
  },
)

app.post(
  '/joins',
  [body('userId').isInt(), body('groupName').isString()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    let data

    const currentDate = moment().format('MM-DD-YYYY')

    try {
      data = await pool.query(
        `INSERT INTO Joins
        (joinDate, userID, groupname)
        values 
        ($1,$2,$3)
      `,
        [currentDate, req.body.userId, req.body.groupName],
      )
    } catch (error) {
      return res.status(400).json({ errors: error })
    }
    res.send({ data })
  },
)

// *************************** //
//           Events            //
// *************************** //

app.get('/users/events', [query('userId').isInt()], async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }
  let data = await pool.query(
    `
      select OE.organizer, OE.eventDate, OE.venue, OE.eventName
			from OrganizedEvent OE inner join Joins J on OE.organizer = J.groupName
			where J.userID = $1;
    `,
    [req.query.userId],
  )
  res.send({ data })
})

app.post(
  '/events',
  [
    body('organizer').isString(),
    body('eventName').isString(),
    body('eventDate').isString(),
    body('venue').isString(),
  ],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    let data = await pool.query(
      `
      INSERT INTO OrganizedEvent
        (eventDate,eventName,venue,organizer)
      values($1,$2,$3,$4)
    `,
      [
        req.body.eventDate,
        req.body.eventName,
        req.body.venue,
        req.body.organizer,
      ],
    )
    res.send({ data })
  },
)

// *************************** //
//        Miscellaneous        //
// *************************** //

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
