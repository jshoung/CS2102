import moment from 'moment'

export const parseMDYLongDate = (dateString: any) => {
  return moment(dateString).format('LL')
}
