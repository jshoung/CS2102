import moment from 'moment'

export const parseMDYDate = (dateString: string) => {
  return moment(dateString).format('MM-DD-YYYY')
}
