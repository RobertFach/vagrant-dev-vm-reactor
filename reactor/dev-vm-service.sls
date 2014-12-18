#!py

# key generation, f.e. or hook in LDAP, project database, etc.
# mkpasswd | openssl md5
# copy key into service key field of projmap
# (type in some random values, do never user the projectname)

projmap = {
#       '<projectname>' : '<servicekey>'
        'test-dev-vm' : '96e8568201c796d637276dec2699ad6f',
        'linux-dev-vm' : 'ac6da72a8caf7795fa5c22e940ccd6b1'
}

def run():
        '''
        Run the reactor
        '''

        ret = {}
        msg = data['post']

        for proj,key in projmap.iteritems():
                if msg['id'].startswith('%s-' % proj):
                        if msg['key'] == key:
                                if msg['action'] == 'register':
                                        ret = {
                                                'minion_add' : {
                                                        'wheel.key.accept' : [
                                                                { 'match' : msg['id'] }
                                                        ]
                                                }
                                        }
                                if msg['action'] == 'unregister':
                                        ret = {
                                                'minion_remove': {
                                                        'wheel.key.delete' : [
                                                                { 'match' : msg['id'] }
                                                        ]
                                                }
                                        }
        return ret

