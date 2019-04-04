import moment from 'moment'

export const parseMDYDate = (dateString: any) => {
  return moment(dateString).format('MM-DD-YYYY')
}
