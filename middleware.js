const { checkSchema } = require('express-validator/check')

const checkInvoicedLoanSchema = checkSchema({
  startDate: {
    isString: true,
    errorMessage: 'startDate is not in Date format',
  },
  endDate: {
    isString: true,
    errorMessage: 'endDate is not in Date format',
  },
  penalty: {
    isInt: true,
    errorMessage: 'penalty is not an integer',
  },
  loanFee: {
    isInt: true,
    errorMessage: 'loanFee is not an integer',
  },
  loanerID: {
    isInt: true,
    errorMessage: 'loanerID is not an integer',
  },
  borrowerID: {
    isInt: true,
    errorMessage: 'borrowerID is not an integer',
  },
  invoiceID: {
    isInt: true,
    errorMessage: 'invoiceID is not an integer',
  },
  itemID: {
    isInt: true,
    errorMessage: 'itemID is not an integer',
  },
})

module.exports = {
  checkInvoicedLoanSchema,
}
