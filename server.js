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

app.get('/items', async (req, res) => {
  const data = await pool.query('select * from loanerItem')

  res.send({ data })
})

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
    'insert into loaneritem (itemname, value, itemdescription, userid, loanfee, loanduration) values ($1, $2, $3, $4, $5, $6)',
    [
      req.body.itemName,
      req.body.itemValue,
      req.body.itemDesc,
      req.body.userId,
      req.body.loanFee,
      req.body.loanDuration,
    ],
  )
  res.sendStatus(200)
})

app.patch('/add-item', async (req, res) => {
  await pool.query(
    'update loaneritem set itemname = $1, value = $2, itemdescription = $3, userid = $4, loanfee = $5, loanduration = $6 where itemid = $7',
    [
      req.body.itemName,
      req.body.itemValue,
      req.body.itemDesc,
      req.body.userId,
      req.body.loanFee,
      req.body.loanDuration,
      req.body.itemId,
    ],
  )
  res.sendStatus(200)
})

// *************************** //
//        Invoiced Loans       //
// *************************** //

app.post(
  '/users/loans',
  [
    body('loanerId').isInt(),
    body('borrowerId').isInt(),
    body('itemId').isInt(),
  ],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }

    const currentDate = moment().format('MM-DD-YYYY')
    let data
    try {
      data = await pool.query(
        `call insertNewInvoicedLoan($1,$2,$3,$4)
        `,
        [currentDate, req.body.loanerId, req.body.borrowerId, req.body.itemId],
      )
    } catch (error) {
      return res.status(400).json({ errors: error })
    }

    res.send({ data })
  },
)

app.patch(
  '/users/loanreturn',
  [body('invoiceId').isInt(), body('isReturned').isBoolean()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }

    // Check whether InvoicedLoan exists in database
    const { rowCount } = await pool.query(
      'select invoiceID from InvoicedLoan where invoiceID = $1',
      [req.body.invoiceId],
    )
    if (!rowCount) {
      return res
        .status(404)
        .json({ errors: 'InvoicedLoan not found in the database' })
    }

    let data
    try {
      data = await pool.query(`call updateStatusOfLoanedItem($1, $2)`, [
        req.body.isReturned,
        req.body.invoiceId,
      ])
    } catch (error) {
      return res.status(400).json({ errors: error })
    }

    res.send({ data })
  },
)

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
        `select startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID,itemName, value, itemDescription, name, isReturned
        from (InvoicedLoan IL 
              natural join 
              LoanerItem)
              inner join UserAccount UA
              on IL.borrowerID = UA.userID
          where IL.loanerID = $1 order by startDate desc`,
        [req.query.userId],
      )
    } else {
      // Otherwise
      data = await pool.query(
        `select startDate,endDate,penalty,loanFee,loanerID,borrowerID,invoiceID,itemID,itemName, value, itemDescription,name, isReturned
        from InvoicedLoan IL 
              natural join 
              LoanerItem
              inner join UserAccount UA
              on IL.loanerID = UA.userID
          where IL.borrowerID = $1 order by startDate desc`,
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
//       Advertisements        //
// *************************** //

app.get('/advertisements', async (req, res) => {
  const data = await pool.query('select * from advertisement')

  res.send({ data })
})

app.post(
  '/insertbid',
  [body('borrowerId').isInt(), body('advId').isInt(), body('bidPrice').isInt()],
  async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() })
    }
    const currentDate = moment().format('DD-MM-YYYY')
    let data = await pool
      .query(
        `
      call insertNewBid($1, $2, $3, $4)
    `,
        [req.body.borrowerId, req.body.advId, currentDate, req.body.bidPrice],
      )
      .catch((err) => console.log(err))
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
      select OE.organizer, OE.eventDate, OE.venue, OE.eventName, OE.eventID
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
    let data

    try {
      data = await pool.query(
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
    } catch (error) {
      res.status(400).json({ errors: error })
    }

    res.send({ data })
  },
)

app.delete('/events', [query('eventId').isInt()], async (req, res) => {
  const errors = validationResult(req)
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() })
  }
  let data = await pool.query(
    `
      delete from OrganizedEvent where eventID = $1
    `,
    [req.query.eventId],
  )
  res.send({ data })
})

// *************************** //
//       Complex Queries       //
// *************************** //

app.get('/bigfan', async (req, res) => {
  const data = await pool.query('select * from bigFanAward')
  res.send({ data })
})

app.get('/enemy', async (req, res) => {
  const data = await pool.query('select * from enemy')
  res.send({ data })
})

app.get('/popular', async (req, res) => {
  const data = await pool.query('select * from popularItem')
  res.send({ data })
})

// ******************* //
//        Reports      //
// ******************* //

app.get('/reports', async (req, res) => {
  let data = await pool.query('select * from report where reporter = $1', [
    req.query.userId,
  ])

  res.send({ data })
})

app.post('/reports', async (req, res) => {
  await pool.query(
    'insert into report (title, reportdate, reason, reporter, reportee) values ($1, $2, $3, $4, $5)',
    [
      req.body.title,
      req.body.reportdate,
      req.body.reason,
      req.body.reporter,
      req.body.reportee,
    ],
  )
  res.sendStatus(200)
})

app.patch('/reports', async (req, res) => {
  await pool.query(
    'update report set title = $1, reportdate = $2, reason = $3, reporter = $4, reportee = $5 where reportid = $6',
    [
      req.body.title,
      req.body.reportdate,
      req.body.reason,
      req.body.reporter,
      req.body.reportee,
      req.body.reportid,
    ],
  )
  res.sendStatus(200)
})

app.delete('/reports', async (req, res) => {
  await pool.query('delete from report where reportid = $1', [
    req.body.reportid,
  ])
  res.sendStatus(200)
})

// *************************** //
//        Miscellaneous        //
// *************************** //

app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname + '/client/build/index.html'))
})

app.listen(port, () => console.log(`Listening on port ${port}`))
