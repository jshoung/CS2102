import moment from 'moment'

<<<<<<< HEAD
export const parseMDYDate = (dateString: any) => {
  return moment(dateString).format('MM-DD-YYYY')
=======
export const parseMDYLongDate = (dateString: any) => {
  return moment(dateString).format('LL')
>>>>>>> e8280facef8a8bcefedbf5aa3c8f79fc2c7cd18a
}
