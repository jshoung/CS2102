import React, { Component, FormEvent } from 'react'
import * as _ from 'lodash'
import { Form, Button } from 'react-bootstrap'
import axios from 'axios'

interface MyProps {
  selectedUser: object
  groupName: string
  groupDescription: string
  groupAdminId: string
  showErrorModal: Function
  fetchInterestGroups: Function
}

interface MyState {
  groupName: string
  groupDescription: string
  groupAdminId: string
  data: object
}

class EditGroupForm extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      groupName: '',
      groupDescription: '',
      groupAdminId: '',
      data: { rows: [] },
    }

    this.handleChange = this.handleChange.bind(this)
  }

  componentDidMount() {
    this.setState({
      groupDescription: this.props.groupDescription,
      groupName: this.props.groupName,
      groupAdminId: this.props.groupAdminId,
    })

    this.fetchMembers()
  }

  fetchMembers = async () => {
    const { data } = await axios.get('/interestgroups/members', {
      params: {
        groupName: this.props.groupName,
      },
    })

    this.setState({ ...data })
  }

  renderMemberOptions = () => {
    const rows = _.get(this.state.data, 'rows')

    return rows.map((row: any) => {
      return <option value={row.userid}>{row.name}</option>
    })
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
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')

    axios
      .patch('/interestgroups', {
        groupDescription: this.state.groupDescription,
        groupName: this.state.groupName,
        userId: userId,
        groupAdminId: this.state.groupAdminId,
      })
      .catch((error) => {
        this.props.showErrorModal(error.response.data.errors.hint)
      })

    this.props.fetchInterestGroups()

    event.preventDefault()
  }

  render() {
    return (
      <Form style={{ flex: '1 1 100%' }} onSubmit={this.handleSubmit}>
        <Form.Group controlId="ControlInput1">
          <Form.Label>Group Name</Form.Label>
          <Form.Control
            name="groupName"
            disabled
            type="text"
            placeholder="Group Name"
            onChange={this.handleChange}
            value={this.state.groupName}
            required
          />
        </Form.Group>
        <Form.Group controlId="ControlSelect1">
          <Form.Label>Group Admin</Form.Label>
          <Form.Control
            name="groupAdminId"
            placeholder="Group Admin"
            onChange={this.handleChange}
            value={`${this.state.groupAdminId}`}
            required
            as="select"
          >
            {this.renderMemberOptions()}
          </Form.Control>
        </Form.Group>
        <Form.Group controlId="ControlInput2">
          <Form.Label>Group Description</Form.Label>
          <Form.Control
            name="groupDescription"
            type="text"
            placeholder="Group Description"
            onChange={this.handleChange}
            value={`${this.state.groupDescription}`}
            required
          />
        </Form.Group>
        <Button variant="primary" type="submit">
          {'Save'}
        </Button>
      </Form>
    )
  }
}

export default EditGroupForm
