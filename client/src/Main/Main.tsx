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

class Main extends Component {
  state = {
    data: {},
    userList: [],
    selectedUser: {},
    selectedTab: '',
    userItems: [],
    content: [],
    isLoading: false,
  }

  async componentDidMount() {
    const payload = (await axios.get(`/users`)).data

    this.setState(
      {
        ...payload,
      },
      () => this.loadUsers(),
    )
  }

  toggleLoading = (callback: () => void) => {
    this.setState({ isLoading: !this.state.isLoading }, callback)
  }

  changeUser = (name: string, userId: number) => {
    this.setState({ selectedUser: { name, userId } }, async () => {
      await this.loadTabData()
    })
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

  updateTab = () => {
    const { userItems, selectedTab, selectedUser } = this.state
    let content: any[] = []

    switch (selectedTab) {
      case 'AddItem':
        content.push(
          <AddItem
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
            loadTabData={this.loadTabData}
            isEditing={false}
          />,
        )
        break
      case 'Items':
        userItems.forEach((row) => {
          const popover = (
            <Popover
              id="popover-basic"
              title="Edit Item"
              style={{ width: '18rem' }}
            >
              <AddItem
                selectedUser={selectedUser}
                toggleLoading={this.toggleLoading}
                loadTabData={this.loadTabData}
                selectedItem={row}
                isEditing={true}
              />
            </Popover>
          )

          content.push(
            <CardDeck style={{ paddingBottom: '10px' }}>
              <Card
                className="text-center"
                bg="dark"
                text="white"
                border="dark"
                style={{ width: '18rem' }}
              >
                <Card.Body>
                  <Card.Title>
                    {_.get(row, 'itemname')}{' '}
                    <OverlayTrigger
                      rootClose={true}
                      trigger="click"
                      placement="right"
                      overlay={popover}
                    >
                      <Icon.Edit style={{ cursor: 'pointer' }} />
                    </OverlayTrigger>
                  </Card.Title>
                  <Card.Subtitle>Price: ${_.get(row, 'value')}</Card.Subtitle>
                  <Card.Text>
                    Description: {_.get(row, 'itemdescription')}
                  </Card.Text>
                </Card.Body>
                <Card.Footer>
                  <div>
                    <Button variant="light" size="sm">
                      Put Up For Loan
                    </Button>
                  </div>
                </Card.Footer>
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

    this.setState({ content })
  }

  loadTabData = async () => {
    const { selectedUser } = this.state
    const userId = _.get(selectedUser, 'userId')

    const items = await axios.post(`/users/items`, {
      userId,
    })
    this.setState({ userItems: items.data.data.rows }, () => {
      this.updateTab()
    })
  }

  changeTab = (selectedTab: string) => {
    this.setState({ selectedTab }, this.loadTabData)
  }

  render() {
    const {
      selectedTab,
      selectedUser,
      userList,
      content,
      isLoading,
    } = this.state

    return (
      <>
        <NavBar selectedUser={selectedUser} userList={userList} />
        {isLoading ? (
          <div style={{ textAlign: 'center' }}>
            <Spinner animation="border" role="status" />
          </div>
        ) : (
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
        )}
      </>
    )
  }
}

export default Main
