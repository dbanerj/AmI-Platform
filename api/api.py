import json
import bottle
from bottle import route, run, request, abort
from pymongo import Connection
from core import settings

@route('/latest_kinect_rgb', method='GET')
def get_latest_kinect_rgb():
    connection = Connection(settings.MONGO_SERVER)
    db = connection.measurements.docs
    image = db.find({'sensor_type': 'kinect_rgb'}, limit = 1).sort('created_at', -1)[0]
    del image['_id']
    return json.dumps(image)

run(host='0.0.0.0', port=8000)