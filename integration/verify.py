import sys
from os import listdir
from os.path import dirname, join, abspath, isdir
import time
from subprocess import check_output

app_path = join(dirname(__file__), '..')
sys.path.append(join(app_path, 'src'))

lib_path = join(app_path, 'lib')
libs = [abspath(join(lib_path, item)) for item in listdir(lib_path) if isdir(join(lib_path, item))]
map(lambda x: sys.path.insert(0, x), libs)

import requests
from bs4 import BeautifulSoup

device_user = 'user'
device_password = 'password'


def test_activate_device(auth):
    email, password, domain, release, version, arch = auth
    response = requests.post('http://localhost:81/server/rest/activate',
                             data={'redirect-email': email, 'redirect-password': password, 'redirect-domain': domain,
                                   'name': device_user, 'password': device_password,
                                   'api-url': 'http://api.syncloud.info:81', 'domain': 'syncloud.info',
                                   'release': release})
    assert response.status_code == 200


def test_install(auth):
    __local_install(auth)

session = requests.session()


def test_visible_through_platform():
    response = session.get('http://localhost/owncloud/', allow_redirects=False)
    assert response.status_code == 200


def test_login():
    response = session.get('http://localhost/owncloud/', allow_redirects=False)
    soup = BeautifulSoup(response.text, "html.parser")
    requesttoken = soup.find_all('input', {'name': 'requesttoken'})[0]['value']
    response = session.post('http://localhost/owncloud/index.php',
                            data={'user': device_user, 'password': device_password, 'requesttoken': requesttoken},
                            allow_redirects=False)

    assert response.status_code == 302, response.text

    assert session.get('http://localhost/owncloud/core/img/filetypes/text.png').status_code == 200

def test_admin():
    assert session.get('http://localhost/owncloud/index.php/settings/admin').status_code == 200

def test_remove():
    session.post('http://localhost/server/rest/login', data={'name': device_user, 'password': device_password})
    response = session.get('http://localhost/server/rest/remove?app_id=owncloud', allow_redirects=False)
    assert response.status_code == 200


def test_reinstall(auth):
    __local_install(auth)


def __local_install(auth):
    email, password, domain, release, version, arch = auth
    ssh = 'sshpass -p syncloud ssh -o StrictHostKeyChecking=no -p 2222 root@localhost'
    print(check_output('{0} /opt/app/sam/bin/sam --debug install /owncloud-{1}-{2}.tar.gz'.format(ssh, version, arch),
                       shell=True))
    time.sleep(3)
