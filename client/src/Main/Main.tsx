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
  Form,
} from 'react-bootstrap'

import NavBar from '../NavBar/NavBar'

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
      case 'AddItem':
        content.push(
          <Form>
            <Form.Group controlId="exampleForm.ControlInput1">
              <Form.Label>Email address</Form.Label>
              <Form.Control type="email" placeholder="name@example.com" />
            </Form.Group>
            <Form.Group controlId="exampleForm.ControlSelect1">
              <Form.Label>Example select</Form.Label>
              <Form.Control as="select">
                <option>1</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </Form.Control>
            </Form.Group>
            <Form.Group controlId="exampleForm.ControlSelect2">
              <Form.Label>Example multiple select</Form.Label>
              <Form.Control as="select" multiple>
                <option>1</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </Form.Control>
            </Form.Group>
            <Form.Group controlId="exampleForm.ControlTextarea1">
              <Form.Label>Example textarea</Form.Label>
              <Form.Control as="textarea" rows="3" />
            </Form.Group>
          </Form>,
        )
      case 'Items':
        userItems.forEach((row) => {
          content.push(
            <CardDeck style={{ paddingBottom: '10px' }}>
              <Card
                className="text-center"
                bg="light"
                border="dark"
                style={{ width: '18rem' }}
              >
                <Card.Header>Header</Card.Header>
                <Card.Body>
                  <Card.Title>{_.get(row, 'itemname')}</Card.Title>
                  <Card.Subtitle>Price: {_.get(row, 'value')}</Card.Subtitle>
                  <Card.Text>{_.get(row, 'itemdescription')}</Card.Text>
                </Card.Body>
                <Card.Footer>Item Id: {_.get(row, 'itemid')}</Card.Footer>
              </Card>
            </CardDeck>,
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

    if (content.length === 0) {
      content.push(
        <CardDeck style={{ paddingBottom: '10px' }}>
          <Card
            className="text-center"
            bg="light"
            border="dark"
            style={{ width: '18rem' }}
          >
            <Card.Body>
              <Card.Title>No data to display</Card.Title>
            </Card.Body>
          </Card>
        </CardDeck>,
      )
    }

    this.setState({ content })
  }

  changeTab = (selectedTab: string) => {
    this.setState({ selectedTab }, this.loadTabData)
  }

  render() {
    const { selectedTab, selectedUser, userList, content } = this.state

    return (
      <>
        <NavBar selectedUser={selectedUser} userList={userList} />
        <Container>
          <Row>
            <Col>
              <Nav
                className="justify-content-center"
                variant="pills"
                activeKey={selectedTab}
                style={{ height: '50px' }}
              >
                <Nav.Item>
                  <Nav.Link
                    eventKey="AddItem"
                    onSelect={() => this.changeTab('AddItem')}
                  >
                    Add Item
                  </Nav.Link>
                </Nav.Item>
                <Nav.Item>
                  <Nav.Link
                    eventKey="Items"
                    onSelect={() => this.changeTab('Items')}
                  >
                    Your Items
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
            </Col>
          </Row>
          <Row style={{ paddingBottom: '20px' }}>
            <Col>{content}</Col>
          </Row>
        </Container>
      </>
    )
  }
}

export default Main
