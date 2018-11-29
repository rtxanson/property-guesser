import os, sys

from flask import Flask, jsonify, json
from flask_cors import CORS
import yaml

app = Flask(__name__)
CORS(app)

@app.route("/img/<_id>")
def get_img(_id):
    from imagegen import StreetViewImage

    if_apn_exists = _id
    has_records = [a for a in app.records if a.get('APN') == _id]

    try:
        rec = has_records[0]
    except:
        rec = {}

    record = {
        "address": rec.get('FORMATTED_ADDRESS'),
        "city": "Minneapolis",
        "state": "MN",
        "floors": rec.get('NUM_STORIES'),
        "filename": if_apn_exists + ".jpg" # PID
    }

    try:
        noimg = False
        with open(path + '/' + record.get('fielname'), 'r') as IMG:
            pass
    except:
        noimg = True

    if noimg:
        img = StreetViewImage(record)

        image = img.get_streetview_image(app.conf_stuff['streetview'])

        path = os.path.join(
            app.root_path,
            'image_cache'
        )
        val = image.getvalue()
        with open(path + '/' + record.get('filename'), 'w') as F:
            F.write(val)
    else:
        with open(path + '/' + record.get('filename'), 'w') as F:
            val = F.read()

    return val

    ## # Get the streetview image and upload it
    ## # ("sv.jpg" is a dummy value, since filename is a required parameter).
    ## media = api.media_upload('sv.jpg', file=image)



@app.route("/")
def hello():
    with open('public/tmp.json', 'r') as F:
        j = json.loads(F.read())

        return jsonify(j)

def init():
    with open('server-conf.yaml', 'r') as CONF:
        conf = yaml.load(CONF.read())

    # TODO: a standin for live data
    with open('public/tmp.json', 'r') as F:
        records = json.loads(F.read())

    app.conf_stuff = conf
    app.records = records
    app.run(debug=True, threaded=True,)

if __name__ == "__main__":
    sys.exit(init())
