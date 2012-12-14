#! /usr/bin/env python
# encoding: utf-8
# Thomas Nagy 2011 (ita)

"""
A simple TCP server to cache files over the network.
The client is located in waflib/extras/netcache_client.py

This server uses a LRU cache policy (remove least recently used files), which means
that there is no risk of filling up the entire filesystem.

Security:
---------
+ the LRU cache policy will prevent filesystem saturation
+ invalid queries will be rejected (no risk of reading/writing arbitrary files on the OS)
- attackers might poison the cache

Performance:
------------
The server seems to work pretty well (for me) at the moment. cPython is limited to only
one CPU core, but there is a Java version of this server (Netcache.java). Send your
performance results to the Waf mailing-list!

Future ideas:
-------------
- File transfer integrity
- Use servers on different ports (eg: get->1200, put->51201) to enable firewall filtering
- Use different processes for get/put (performance improvement)
"""

import os, re, tempfile, socket, threading, shutil
import SocketServer

CACHEDIR = '/tmp/wafcache'
CONN = (socket.gethostname(), 51200)
HEADER_SIZE = 128
BUF = 8192*16
MAX = 50*1024*1024*1024 # in bytes
CLEANRATIO = 0.85
CHARS = '0123456789abcdef'

GET = 'GET'
PUT = 'PUT'
LST = 'LST'
BYE = 'BYE'
CLEAN = 'CLN'
RESET = 'RST'

re_valid_query = re.compile('^[a-zA-Z0-9_, ]+$')

flist = {}
def init_flist():
	"""map the cache folder names to the timestamps and sizes"""
	global flist
	try:
		os.makedirs(CACHEDIR)
	except:
		pass
	flist = {}
	for x in os.listdir(CACHEDIR):
		if len(x) != 2:
			continue
		for y in os.listdir(os.path.join(CACHEDIR, x)):
			path = os.path.join(CACHEDIR, x, y)
			size = 0
			for z in os.listdir(path):
				size += os.stat(os.path.join(path, z)).st_size
				flist[y] = [os.stat(path).st_mtime, size]

lock = threading.Lock()
def make_clean():
	global lock
	# there is no need to spend a lot of time cleaning
	# so one thread cleans and the others return immediately

	if lock.acquire(0):
		try:
			make_clean_unsafe()
		finally:
			lock.release()

def make_clean_unsafe():
	global MAX, flist
	# and do some cleanup if necessary
	total = sum([x[1] for x in flist.values()])

	#print("and the total is %d" % total)
	if total >= MAX:
		print("Trimming the cache since %r > %r" % (total, MAX))
		lst = [(p, v[0], v[1]) for (p, v) in flist.items()]
		lst.sort(key=lambda x: x[1]) # sort by timestamp
		lst.reverse()

		while total >= MAX * CLEANRATIO:
			(k, t, s) = lst.pop()
			shutil.rmtree(os.path.join(CACHEDIR, k[:2], k))
			total -= s
			del flist[k]

def reset():
	global MAX, flist
	tmp = list(flist.keys())
	lock.acquire()
	try:
		flist = {}
	finally:
		lock.release()
	for x in CHARS:
		for y in CHARS:
			try:
				os.rename(os.path.join(CACHEDIR, x+y), os.path.join(CACHEDIR, x+y+'_rm'))
			except:
				pass
	for x in CHARS:
		for y in CHARS:
			try:
				shutil.rmtree(os.path.join(CACHEDIR, x+y+'_rm'))
			except:
				pass


def update(ssig):
	"""update the cache folder and make some space if necessary"""
	global flist
	# D, T, S : directory, timestamp, size

	# update the contents with the last folder created
	cnt = 0
	d = os.path.join(CACHEDIR, ssig[:2], ssig)
	for k in os.listdir(d):
		cnt += os.stat(os.path.join(d, k)).st_size

	# the same thread will usually push the next files
	try:
		flist[ssig][1] = cnt
	except:
		flist[ssig] = [os.stat(d).st_mtime, cnt]

class req(SocketServer.StreamRequestHandler):
	def handle(self):
		while 1:
			try:
				self.process_command()
			except Exception as e:
				print(e)
				break

	def process_command(self):
		query = self.rfile.read(HEADER_SIZE).strip()
		#print "%r" % query
		if not re_valid_query.match(query):
			raise ValueError('Invalid query %r' % query)

		query = query.strip().split(',')

		if query[0] == GET:
			self.get_file(query[1:])
		elif query[0] == PUT:
			self.put_file(query[1:])
		elif query[0] == LST:
			self.lst_file(query[1:])
		elif query[0] == CLEAN:
			make_clean()
		elif query[0] == RESET:
			reset()
		elif query[0] == BYE:
			raise ValueError('Exit')
		else:
			raise ValueError('Invalid query %r' % query)

	def lst_file(self, query):
		response = '\n'.join(flist.keys())
		params = [str(len(response)),'']
		self.wfile.write(','.join(params).ljust(HEADER_SIZE))
		self.wfile.write(response)

	def get_file(self, query):
		# get a file from the cache if it exists, else return 0
		tmp = os.path.join(CACHEDIR, query[0][:2], query[0], query[1])
		fsize = -1
		try:
			fsize = os.stat(tmp).st_size
		except Exception:
			#print(e)
			pass
		else:
			# cache was useful, update the last access for LRU
			d = os.path.join(CACHEDIR, query[0][:2], query[0])
			os.utime(d, None)
			flist[query[0]][0] = os.stat(d).st_mtime
		params = [str(fsize)]
		self.wfile.write(','.join(params).ljust(HEADER_SIZE))

		if fsize < 0:
			#print("file not found in cache %s" % query[0])
			return
		f = open(tmp, 'rb')
		try:
			cnt = 0
			while cnt < fsize:
				r = f.read(BUF)
				self.wfile.write(r)
				cnt += len(r)
		finally:
			f.close()

	def put_file(self, query):
		# add a file to the cache, the third parameter is the file size
		(fd, filename) = tempfile.mkstemp(dir=CACHEDIR)
		try:
			size = int(query[2])
			cnt = 0
			while cnt < size:
				r = self.rfile.read(min(BUF, size-cnt))
				if not r:
					raise ValueError('Connection closed')
				os.write(fd, r)
				cnt += len(r)
		finally:
			os.close(fd)


		d = os.path.join(CACHEDIR, query[0][:2], query[0])
		try:
			os.stat(d)
		except:
			try:
				# obvious race condition here
				os.makedirs(d)
			except OSError:
				pass
		try:
			os.rename(filename, os.path.join(d, query[1]))
		except OSError:
			pass # folder removed by the user, or another thread is pushing the same file
		try:
			update(query[0])
		except OSError:
			pass
		make_clean()

class req_only_get(req):
	def put_file(self, query):
		self.wfile.write('ERROR,'.ljust(HEADER_SIZE))
		raise ValueError('Put is forbidden')

class req_only_put(req):
	def get_file(self, query):
		self.wfile.write('ERROR,'.ljust(HEADER_SIZE))
		raise ValueError('Get is forbidden')

def create_server(conn, cls):
	SocketServer.ThreadingTCPServer.allow_reuse_address = True
	server = SocketServer.ThreadingTCPServer(CONN, req)
	server.timeout = 60 # seconds
	server.serve_forever()

if __name__ == '__main__':
	init_flist()
	print("ready (%r dirs)" % len(flist.keys()))
	create_server(CONN, req)

