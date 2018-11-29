all: dist/elm.js

env:
	virtualenv -p python2.7 env
	. env/bin/activate && pip install -r requirements.txt
	npm install

dist/elm.js:
	elm make src/Main.elm --optimize --output=dist/elm.js
	uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | uglifyjs --mangle --output=dist/elm.min.js

