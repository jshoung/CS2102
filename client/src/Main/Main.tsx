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
import UserInterestGroups from '../Components/UserInterestGroups'
import InterestGroups from '../InterestGroups/InterestGroups'
import ReportUser from '../Components/ReportUser'

class Main extends Component {
  state = {
    data: {},
    userList: [],
    selectedUser: {},
    selectedTab: '',
    userItems: [],
    content: [],
    reports: [],
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

  renderItems = (content: any[]) => {
    const { userItems, selectedUser } = this.state

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
              <Card.Subtitle className={'mb-2'}>
                Item Value: ${_.get(row, 'value')} | Loan Fee: $
                {_.get(row, 'loanfee')} | Loan Duration:{' '}
                {_.get(row, 'loanduration')} Days
              </Card.Subtitle>
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
  }

  getReportsById = (reportee: number) => {
    const { reports } = this.state

    const matchingReport = reports.filter((report) => {
      return _.get(report, 'reportee') === reportee
    })

    if (!matchingReport.length) {
      return
    }

    return matchingReport[0]
  }

  renderBrowseUsers = (content: any[]) => {
    const { data, selectedUser } = this.state

    _.get(data, 'rows').forEach((row: any) => {
      const name = row.name
      const reporter = _.get(selectedUser, 'userId')
      const reportee = _.get(row, 'userid')
      if (reporter === reportee) {
        return
      }
      const existingReport = this.getReportsById(reportee)
      const title = existingReport ? 'Edit Report' : 'Report User'
      const popover = (
        <Popover id="popover-basic" title={title} style={{ width: '18rem' }}>
          <ReportUser
            reporter={reporter}
            toggleLoading={this.toggleLoading}
            loadTabData={this.loadTabData}
            reportee={reportee}
            existingReport={existingReport}
            isEditing={!!existingReport}
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
              <Card.Title>{name}</Card.Title>
            </Card.Body>
            <Card.Footer>
              <OverlayTrigger
                rootClose={true}
                trigger="click"
                placement="right"
                overlay={popover}
              >
                <Button variant="light" size="sm">
                  {title}
                </Button>
              </OverlayTrigger>
            </Card.Footer>
          </Card>
        </CardDeck>,
      )
    })
  }

  updateTab = () => {
    const { selectedTab, selectedUser } = this.state
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
        this.renderItems(content)
        break
      case 'Browse Users':
        this.renderBrowseUsers(content)
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
    const reports = await axios.post(`/reports`, {
      userId,
    })
    this.setState(
      { userItems: items.data.data.rows, reports: reports.data.data.rows },
      () => {
        this.updateTab()
      },
    )
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
                      eventKey="Browse Users"
                      onSelect={() => this.changeTab('Browse Users')}
                      disabled={_.isEmpty(selectedUser)}
                    >
                      Browse Users
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
            selectedUser={this.state.selectedUser}
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
    const { selectedUser, userList, isLoading, pageToRender } = this.state

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
