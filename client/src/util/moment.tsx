import moment from 'moment'

export const parseMDYDate = (dateString: any) => {
  return moment(dateString).format('LL')
}
