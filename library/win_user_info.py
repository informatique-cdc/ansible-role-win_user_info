#!/usr/bin/python
# -*- coding: utf-8 -*-

# This is a windows documentation stub.  Actual code lives in the .ps1
# file of the same name.

# Copyright 2020 Informatique CDC. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_user_info
short_description: Gather facts about local Windows user accounts
author:
    - Stéphane Bilqué (@sbilque) Informatique CDC
description:
    - This Ansible module gets information from local Windows user accounts.
seealso:
- module: win_user
'''

EXAMPLES = r'''
---
- name: test the win_user_info module
  hosts: all
  gather_facts: false

  roles:
    - win_user_info

  tasks:
    - name: Gather facts about all local Windows user accounts
      win_user_info:
      register: all_users_info

    - name: Displays the facts
      debug:
        var: all_users_info

    - name: Gather facts about local Windows administrator user account
      win_user_info:
        sid: '*-500'
      register: admin_user_info

    - name: Displays the facts
      debug:
        var: admin_user_info

    - name: Gather facts about local Windows user account whose name begin with admin
      win_user_info:
        name: 'admin*'
      register: admin_user_info

    - name: Displays the facts
      debug:
        var: admin_user_info
'''

RETURN = r'''
local_user_info:
    description: Metadata about local Windows users.
    returned: success
    type: complex
    contains:
        account_disabled:
            description:
                - Indicates whether the account is disabled.
            type: bool
        account_locked:
            description:
                - Indicates whether the account is locked.
            type: bool
        description:
            description:
                - Description of the user.
            type: str
        fullname:
            description:
                - Full name of the user.
            type: str
        groups:
            description:
                - List of groups.
            type: list
        home_directory:
            description:
                - The designated home directory of the user.
            type: str
        last_logon:
            description:
                - The date and time when the last logon occurred.
            type: str
        login_script:
            description:
                - The login script of the user.
            type: str
        name:
            description:
                - Name of the user.
            type: str
        password_changeable_date:
            description:
                - Indicates the date with the user have to change their password.
        password_expired:
            description:
                - Indicates whether user have to change their password at next login.
            type: bool
        password_last_set:
            description:
                - Indicates the date of password last set.
            type: str
        password_never_expires:
            description:
                - Indicates whether the password never expires.
            type: bool
        password_required:
            description:
                - Indicates whether the password is required.
            type: bool
        profile:
            description:
                - The profile path of the user.
            type: str
        user_cannot_change_password:
            description:
                - Indicates whether the user can change their password.
            type: bool
'''
