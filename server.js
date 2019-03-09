const express = require('express')
const bodyParser = require('body-parser')
const path = require('path')
const compression = require('compression')
const morgan = require('morgan')
const helmet = require('helmet')
const { Pool } = require('pg')
const env = require('./env')
const cors = require('cors')

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
app.use(cors())

/* This endpoint gets all the users currently in the database
   Might need to specify parameters in req if we want to do filtering
*/
app.post('/stuffshare/users', async (req, res) => {
  const client = await pool.connect()
  let data
  data = await client.query('select * from useraccount')
  
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
