import React, { Component } from "react";
import { Menu } from "semantic-ui-react";

class Header extends Component {
  render() {
    return (
      <Menu style={{ marginTop: "10px" }} color="blue" inverted>
        <Menu.Item name="home">{/* <img src={} width="30" height="30" alt="" /> */}</Menu.Item>
        <Menu.Item name="messages">&nbsp;SimpleFi's NFT rewarder</Menu.Item>
        <Menu.Menu position="right">
          <Menu.Item name="Acc">{this.props.account}</Menu.Item>
        </Menu.Menu>
      </Menu>
    );
  }
}

export default Header;
