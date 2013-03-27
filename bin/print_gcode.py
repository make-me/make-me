#!/usr/bin/env python
from datetime import datetime
import os
import sys
lib_path = os.path.abspath(os.path.dirname(__file__) + '/../vendor/s3g')
sys.path.append(lib_path)
import makerbot_driver

import serial
import serial.tools.list_ports as lp
import optparse

parser = optparse.OptionParser()
parser.add_option("-f", "--filename", dest="filename",
                  help="gcode file to print", default=False)
parser.add_option("-m", "--machine", dest="machine",
                  help="machine type to scan for, example ReplicatorSingle", default="The Replicator")

parser.add_option("-p", "--port", dest="port",
                  help="The port you want to connect to (OPTIONAL)", default=None)
parser.add_option("-s", "--sequences", dest="sequences",
                  help="Flag to not use makerbot_driver's start/end sequences",
                  default=True, action="store_false")
(options, args) = parser.parse_args()

if options.port is None:
    md = makerbot_driver.MachineDetector()
    md.scan(options.machine)
    port = md.get_first_machine()
    if port is None:
        print "Can't Find %s" % (options.machine)
        sys.exit()
else:
    port = options.port
factory = makerbot_driver.MachineFactory()
obj = factory.build_from_port(port)
profile = getattr(obj, 'profile')

assembler = makerbot_driver.GcodeAssembler(profile)
start, end, variables = assembler.assemble_recipe()
start_position = profile.values['print_start_sequence']['start_position']
variables['START_X'] = start_position['start_x']
variables['START_Y'] = start_position['start_y']
variables['START_Z'] = start_position['start_z']
start_gcode = assembler.assemble_start_sequence(start)
end_gcode = assembler.assemble_end_sequence(end)

filename = os.path.basename(options.filename)
filename = os.path.splitext(filename)[0]

parser = getattr(obj, 'gcodeparser')
parser.environment.update(variables)
parser.state.values["build_name"] = filename[:15]

if options.sequences:
    for line in start_gcode:
        parser.execute_line(line)

print "==%s==> Starting gcode stream" % datetime.now()
with open(options.filename) as f:
    lines = list(f)
    num_lines = len(lines)
    interval = round(num_lines * 0.01)
    for n, line in enumerate(lines):
        parser.execute_line(line)
        percent = round(float(n) / float(num_lines) * 100.0)
        if n % interval == 0:
            print "==%s==> Sent %d/%d [%d%%]" % (datetime.now(), n, num_lines, percent)
            sys.stdout.flush()

print "==%s==> Gcode stream finished" % datetime.now()


if options.sequences:
    for line in end_gcode:
        parser.execute_line(line)
