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
import BorrowedList from '../Components/BorrowedList'
import BrowseItems from '../Components/BrowseItems'

import NavBar from '../Components/NavBar'
import { parseMDYLongDate } from '../util/moment'
import UserInterestGroups from '../Components/UserInterestGroups'
import InterestGroups from '../InterestGroups/InterestGroups'

class Main extends Component {
  state = {
    data: {},
    userList: [],
    selectedUser: {},
    selectedTab: '',
    userItems: [],
    content: [],
    isLoading: false,
    pageToRender: 'Profile',
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

          const itemDescription = _.get(row, 'itemdescription')
          const borrowerName = _.get(row, 'borrowername')
          const loanFee = _.get(row, 'loanfee')
          const startDate = _.get(row, 'startdate')
          const endDate = _.get(row, 'enddate')
          const penalty = _.get(row, 'penalty')

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
                  <Card.Subtitle>
                    Price: ${_.get(row, 'value')} <br />
                    {borrowerName
                      ? `Loaned to ${borrowerName} for $${loanFee} from ${parseMDYLongDate(
                          startDate,
                        )} to ${parseMDYLongDate(
                          endDate,
                        )} with penalty $${penalty}`
                      : ''}
                  </Card.Subtitle>
                  <Card.Text>
                    Description:{' '}
                    {itemDescription
                      ? `${_.get(row, 'itemdescription')}`
                      : ' - '}
                  </Card.Text>
                </Card.Body>
              </Card>
            </CardDeck>,
          )
        })
        break
      case 'Loans':
        content.push(
          <BorrowedList
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
            loadTabData={this.loadTabData}
          />,
        )
        break
      case 'Interest Groups':
        content.push(
          <UserInterestGroups
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
          />,
        )
      default:
        break
    }

    this.setState({ content })
  }

  renderWelcomeMessage = () => (
    <CardDeck style={{ paddingBottom: '10px' }}>
      <Card
        className="text-center"
        bg="dark"
        text="white"
        border="dark"
        style={{ width: '18rem' }}
      >
        <Card.Body>
          <Card.Title>Welcome to CarouShare!</Card.Title>
        </Card.Body>
      </Card>
    </CardDeck>
  )

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

  renderPage = (page: string) => {
    const { selectedTab, selectedUser, content } = this.state
    switch (page) {
      case 'Profile':
        return (
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
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Add Item
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Items"
                      onSelect={() => this.changeTab('Items')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Your Items
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Loans"
                      onSelect={() => this.changeTab('Loans')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Borrowed Items
                    </Nav.Link>
                  </Nav.Item>
                  <Nav.Item>
                    <Nav.Link
                      eventKey="Interest Groups"
                      onSelect={() => this.changeTab('Interest Groups')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Your Groups
                    </Nav.Link>
                  </Nav.Item>
                </Nav>
              </Col>
            </Row>
            <Row style={{ paddingBottom: '20px' }}>
              <Col>
                {_.isEmpty(selectedTab) ? this.renderWelcomeMessage() : content}
              </Col>
            </Row>
          </Container>
        )
      case 'Interest Groups':
        return (
          <InterestGroups
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
          />
        )

      case 'Browse Items':
        return (
          <BrowseItems
            selectedUser={selectedUser}
            toggleLoading={this.toggleLoading}
          />
        )
      default:
        return
    }
  }

  changePage = (page: string) => {
    this.setState({ pageToRender: page })
  }

  render() {
    const {
      selectedTab,
      selectedUser,
      userList,
      content,
      isLoading,
      pageToRender,
    } = this.state

    return (
      <>
        <NavBar
          selectedUser={selectedUser}
          userList={userList}
          changePage={this.changePage}
        />
        {isLoading ? (
          <div style={{ textAlign: 'center' }}>
            <Spinner animation="border" role="status" />
          </div>
        ) : (
          this.renderPage(pageToRender)
        )}
      </>
    )
  }
}

export default Main
