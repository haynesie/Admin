import paramiko
import sys

def clusterNodeLoad():
    cmd = "/usr/bin/uptime"
    down_systems = []
    for i in range(1,9):
        for j in ('a','b','c','d','e','f','g','h'):
            host = "lab" + str(i) + j
            time = ""
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            try:
                ssh.connect(host, username='keven') 
                stdin, stdout, stderr = ssh.exec_command(cmd)
                time = stdout.readlines()[0].strip()
                if time: 
                    print '%s:  %s' % (host, time)
                ssh.close()
            except:
                print "Trouble with ", host,
                down_systems.append(host)

    if len(down_systems): 
        print "\nCheck on:  ",
        for node in down_systems:
            print node, 

if __name__ == '__main__':
    clusterNodeLoad()
