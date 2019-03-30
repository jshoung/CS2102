import React, { Component } from 'react'
import * as _ from 'lodash'
import axios from 'axios'
import {
  Nav,
  Dropdown,
  Col,
  Row,
  Card,
  CardGroup,
  Container,
} from 'react-bootstrap'

class Main extends Component {
  state = {
    data: {},
    userList: [],
    selectedUser: {},
    selectedTab: '',
    userItems: [],
    content: [],
  }

  async componentDidMount() {
    const payload = (await axios.post(`/users`)).data

    this.setState(
      {
        ...payload,
      },
      () => this.loadUsers(),
    )
  }

  changeUser = async (name: string, userId: number) => {
    const items = await axios.post(`/users/items`, {
      userId,
    })

    this.setState({ selectedUser: { name, userId } })
    this.setState({ userItems: items.data.data.rows }, this.loadTabData)
  }

  loadUsers = () => {
    const { data } = this.state

    let userList: any[] = []
    _.get(data, 'rows').forEach((row: any) => {
      let name = row.name
      let userid = row.userid
      userList.push(
        <Dropdown.Item onSelect={() => this.changeUser(name, userid)}>
          {name}
        </Dropdown.Item>,
      )
    })
    this.setState({ userList })
  }

  loadTabData = () => {
    const { userItems, selectedTab } = this.state
    let content: any[] = []

    switch (selectedTab) {
      case 'Items':
        userItems.forEach((row) => {
          console.log(row)

          content.push(
            <Card>
              <Card.Body>
                <Card.Title>{_.get(row, 'itemname')}</Card.Title>
                <Card.Subtitle>Price: {_.get(row, 'value')}</Card.Subtitle>
                <Card.Text>{_.get(row, 'itemdescription')}</Card.Text>
                <Card.Footer>Item Id: {_.get(row, 'itemid')}</Card.Footer>
              </Card.Body>
            </Card>,
          )
        })
        break
      case 'Loans':
        // content = <div>Loan name</div>
        break
      case 'Other Users':
        // content = <div>Other users</div>
        break
      case 'Past Loans':
        // content = <div>Past Loan name</div>
        break
      default:
        break
    }

    this.setState({ content })
  }

  changeTab = (selectedTab: string) => {
    this.setState({ selectedTab }, this.loadTabData)
  }

  render() {
    const { selectedTab, selectedUser, userList, content } = this.state

    return (
      <Container>
        <Row>
          <Col md={6}>
            <Dropdown>
              <Dropdown.Toggle
                style={{ width: '500px', fontSize: '24px' }}
                variant="primary"
                id="dropdown-basic"
              >
                {_.get(selectedUser, 'name') || 'Select User'}
              </Dropdown.Toggle>
              <Dropdown.Menu
                style={{
                  overflowY: 'scroll',
                  width: '500px',
                  maxHeight: '500px',
                }}
              >
                {userList}
              </Dropdown.Menu>
            </Dropdown>
          </Col>
          <Col>
            <Nav variant="tabs" activeKey={selectedTab}>
              <Nav.Item>
                <Nav.Link
                  eventKey="Items"
                  onSelect={() => this.changeTab('Items')}
                >
                  Items
                </Nav.Link>
              </Nav.Item>
              <Nav.Item>
                <Nav.Link
                  eventKey="Loans"
                  onSelect={() => this.changeTab('Loans')}
                >
                  Loans
                </Nav.Link>
              </Nav.Item>
              <Nav.Item>
                <Nav.Link
                  eventKey="Other Users"
                  onSelect={() => this.changeTab('Other Users')}
                >
                  Other Users
                </Nav.Link>
              </Nav.Item>
              <Nav.Item>
                <Nav.Link
                  eventKey="Past Loans"
                  onSelect={() => this.changeTab('Past Loans')}
                >
                  Past Loans
                </Nav.Link>
              </Nav.Item>
            </Nav>
            <CardGroup>{content}</CardGroup>
          </Col>
        </Row>
      </Container>
    )
  }
}

export default Main
