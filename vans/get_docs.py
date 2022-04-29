#!/usr/bin/python3
"""
Copyright 2022 Jon Vadney
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
"""


from bs4 import BeautifulSoup
import datetime
import time
import json
import requests
import datetime
import os
from urllib.parse import urlparse

__default_headers__ = {'User-Agent': 'Jon Vadney (jon.vadney@gmail.com)',
                       'accept': 'application/json',
                      }

__base_url__ = "https://www.vansaircraft.com/service-information-and-revisions"
sbs_url = f"{__base_url__}/?aircraft=rv-14&doctype=service-bulletins&sort=date"
notifications_url = f"{__base_url__}/?aircraft=rv-14&doctype=notifications-and-letters&sort=date"
revisions_url = f"{__base_url__}/?aircraft=rv-14&doctype=revisions-changes&sort=date"
all_url = f"{__base_url__}/?aircraft=rv-14&doctype=all&sort=date"

def parse_value(html):
  soup = BeautifulSoup(html, features="html.parser")
  results = soup.find_all("div", "service-results__cell-value")

  return results[0].text

def parse_date_html(html):
  dt = datetime.datetime.strptime(parse_value(html), '%B %d, %Y')
 
  return dt

def parse_link(html):
  soup = BeautifulSoup(html, features="html.parser")
  results = soup.find_all("a")
  
  return results[0]['href']

def get_doc_url(link):
  result = session.get(link, headers=__default_headers__)
  soup = BeautifulSoup(result.text, features="html.parser")
  results = soup.find_all("div", "download-button-wrapper")

  a_soup = BeautifulSoup(str(results[0]), features="html.parser")
  link_results = a_soup.find_all("a")

  return link_results[0]['href']

def parse_service_results(type, html):
  soup = BeautifulSoup(html, features="html.parser")
  results = soup.find_all("div", "service-results__row service-results__row--result")

  os.makedirs(f"files/{type}")
  for result in reversed(results):
    soup_result = BeautifulSoup(str(result), features="html.parser")
    parsed_results = soup_result.find_all("div", "service-results__cell")

    id_html = str(parsed_results[0])
    date_html = str(parsed_results[1])
    description_html = str(parsed_results[3])
    link_html = str(parsed_results[4])

    id = parse_value(id_html)
    dt = parse_date_html(date_html)
    dt_str = dt.strftime('%Y-%m-%d')
    description = parse_value(description_html)
    link = parse_link(link_html)
    file_url = get_doc_url(link)
    file_url_parsed = urlparse(file_url)
    orig_filename = os.path.basename(file_url_parsed.path)
    new_filename = f"{orig_filename.rsplit('.', 1)[0]}-{dt_str}.pdf"

    print(f"{id}: {dt_str}: {new_filename}: {file_url}")
    
    file_content = session.get(file_url, headers=__default_headers__)
    open(f"files/{type}/{new_filename}", 'wb').write(file_content.content)

session = requests.Session()
parse_service_results('service-bulletins', session.get(sbs_url, headers=__default_headers__).text)
parse_service_results('notifications', session.get(notifications_url, headers=__default_headers__).text)
parse_service_results('revisions', session.get(revisions_url, headers=__default_headers__).text)


