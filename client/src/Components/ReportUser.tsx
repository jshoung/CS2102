import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'
import moment, { Moment } from 'moment'

interface MyProps {
  reporter: number
  reportee: number
  toggleLoading: (callback: () => void) => void
  isEditing: boolean
  loadTabData: () => Promise<void>
  existingReport?: object
}

interface MyState {
  title: string
  reportdate: Moment
  reason: string
}

class ReportUser extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      title: '',
      reportdate: moment(),
      reason: '',
    }

    this.handleChange = this.handleChange.bind(this)
  }

  componentDidMount() {
    const { existingReport, isEditing } = this.props

    if (isEditing) {
      this.setState({
        title: _.get(existingReport, 'title'),
        reportdate: _.get(existingReport, 'reportdate'),
        reason: _.get(existingReport, 'reason'),
      })
    }
  }

  handleChange = (event: any) => {
    const target = event.target
    const value = target.value
    const name = target.name

    this.setState({
      [name]: value,
    } as any)
  }

  handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    const {
      reporter,
      reportee,
      toggleLoading,
      isEditing,
      loadTabData,
      existingReport,
    } = this.props
    const reportid = _.get(existingReport, 'reportid')

    toggleLoading(async () => {
      isEditing
        ? await axios.patch(`/reports`, {
            ...this.state,
            reporter,
            reportee,
            reportid,
          })
        : await axios.post(`/reports/create`, {
            ...this.state,
            reporter,
            reportee,
            reportdate: moment(),
          })

      await loadTabData()
      toggleLoading(() => {})
    })
    event.preventDefault()
  }

  render() {
    return (
      <Form onSubmit={this.handleSubmit}>
        <Form.Group controlId="ControlInput1">
          <Form.Label>Report Title</Form.Label>
          <Form.Control
            name="title"
            type="text"
            placeholder="Report Title"
            onChange={this.handleChange}
            value={this.state.title}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlInput2">
          <Form.Label>Reason for Report (Optional)</Form.Label>
          <Form.Control
            name="reason"
            type="text"
            placeholder="Reason for Report"
            onChange={this.handleChange}
            value={this.state.reason}
          />
        </Form.Group>
        <Button variant="primary" type="submit">
          {this.props.isEditing ? 'Update' : 'Report'}
        </Button>
      </Form>
    )
  }
}

export default ReportUser
