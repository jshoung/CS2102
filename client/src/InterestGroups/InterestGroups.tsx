import React, { Component } from 'react'
import * as _ from 'lodash'
import axios from 'axios'
import {
  Nav,
  Dropdown,
  Col,
  Row,
  Card,
  Container,
  CardDeck,
  Spinner,
  Button,
  OverlayTrigger,
  Popover,
} from 'react-bootstrap'
import * as Icon from 'react-feather'

import AddItem from '../Components/AddItem'
import NavBar from '../Components/NavBar'

interface MyProps {
  selectedUser: object
  toggleLoading: (callback: () => void) => void
}

interface MyState {
  data: { rows: any }
}

class InterestGroups extends Component<MyProps, MyState> {
  constructor(props: any) {
    super(props)
    this.state = {
      data: { rows: [] },
    }
  }

  async componentDidMount() {
    const { data } = await axios.get(`/interestgroups`)

    this.setState({
      ...data,
    })
  }

  renderInterestGroups(groupList: any) {
    return groupList.map((row: any) => {
      const groupName = _.get(row, 'groupname')
      const groupDescription = _.get(row, 'groupdescription')
      return (
        <CardDeck style={{ paddingBottom: '10px' }}>
          <Card
            className="text-center"
            bg="dark"
            text="white"
            border="dark"
            style={{ width: '18rem' }}
          >
            <Card.Body>
              <Card.Title>{groupName}</Card.Title>
              <Card.Text>
                {groupDescription
                  ? groupDescription
                  : 'This group likes to be mysterious...'}
              </Card.Text>
            </Card.Body>
          </Card>
        </CardDeck>
      )
    })
  }

  render() {
    const { selectedUser } = this.props
    const userId = _.get(selectedUser, 'userId')
    const { rows } = this.state.data

    return (
      <Container>
        <Row style={{ paddingBottom: '20px' }}>
          <Col>{this.renderInterestGroups(rows)}</Col>
        </Row>
      </Container>
    )
  }
}

export default InterestGroups
