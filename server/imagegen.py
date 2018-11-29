#!/usr/env python
# -*- coding: utf-8 -*-

# This file is part of everylotbot
#    - https://github.com/fitnr/everylotbot

# Copyright 2016 Neil Freeman
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from __future__ import unicode_literals
from io import BytesIO
import requests

SVAPI = "https://maps.googleapis.com/maps/api/streetview"
GCAPI = "https://maps.googleapis.com/maps/api/geocode/json"

class StreetViewImage(object):

    # assessorrecord =  {address:, city:, state: }
    def __init__(self, assessorrecord,
                 search_format=None,
                 **kwargs):

        self.record = assessorrecord
        # set address format for fetching from DB
        self.search_format = search_format or '{address}, {city} {state}'

    def aim_camera(self):
        '''Set field-of-view and pitch'''
        fov, pitch = 65, 10
        try:
            floors = float(self.record.get('floors', 0)) or 2
        except TypeError:
            floors = 2

        if floors == 3:
            fov = 72

        if floors == 4:
            fov, pitch = 76, 15

        if floors >= 5:
            fov, pitch = 81, 20

        if floors == 6:
            fov = 86

        if floors >= 8:
            fov, pitch = 90, 25

        if floors >= 10:
            fov, pitch = 90, 30

        return fov, pitch

    def get_streetview_image(self, key):
        '''Fetch image from streetview API'''
        params = {
            "location": self.streetviewable_location(key),
            "key": key,
            "size": "1000x1000"
        }

        params['fov'], params['pitch'] = self.aim_camera()

        r = requests.get(SVAPI, params=params)

        sv = BytesIO()
        for chunk in r.iter_content():
            sv.write(chunk)

        sv.seek(0)
        return sv

    def streetviewable_location(self, key):
        '''
        Check if google-geocoded address is nearby or not. if not, use the lat/lon
        '''
        # skip this step if there's no address, we'll just use the lat/lon to fetch the SV.
        try:
            address = self.search_format.format(**self.record)
        except KeyError:
            return '{},{}'.format(self.record['lat'], self.record['lon'])

        # bounds in (miny minx maxy maxx) aka (s w n e)
        try:
            d = 0.007
            minpt = self.record['lat'] - d, self.record['lon'] - d
            maxpt = self.record['lat'] + d, self.record['lon'] + d

        except KeyError:
            return address

        params = {
            "address": address,
            "key": key,
        }

        try:
            r = requests.get(GCAPI, params=params)

            if r.status_code != 200:
                raise ValueError('bad response from google geocode: %s' % r.status_code)

            loc = r.json()['results'][0]['geometry']['location']

            # Cry foul if we're outside of the bounding box
            outside_comfort_zone = any((
                loc['lng'] < minpt[1],
                loc['lng'] > maxpt[1],
                loc['lat'] > maxpt[0],
                loc['lat'] < minpt[0]
            ))

            if outside_comfort_zone:
                raise ValueError('google geocode puts us outside outside our comfort zone')

            return address

        except Exception as e:
            return '{},{}'.format(self.record['lat'], self.record['lon'])


