#####
# Run this script from qa-infra/script/runtests.
# e.g.: python3 runtests.py -l log.log -o reactors_options.json
#
# It will replace the Makefile and testnet.toml files in qa-infra, that is, ../../.
# Do not commit the updated files!!!
#
# If the Makefile and testnet.toml files are updated, the templates in this folder should
# also be updated.
####


from __future__ import print_function

from __future__ import absolute_import

import os
import sys
import time
from datetime import datetime
import getopt
import pexpect
import pathlib
import json
import logging as log
import itertools
import requests

global_pexpect_instance = None  # Used by signal handler
global_output_folder = str(pathlib.Path(__file__).parents[2])
global_COMMAND_PROMPT = r"\[PEXPECT\]\$ "

def exit_with_usage():

    print(globals()['__doc__'])
    print(
    '''Usage: runtests.py [-s|--single-pass] [-l|--log logFile] [o|--options optionsFile] [-i|--interactive] [-a|--append] [-r|--retrieve [-d|--destroy]] [-t|--tag-experiment] 
        -s: applies configuration once and quit 
        -l: output log file
        -o: tag replacements file
        -i: pause on some key steps
        -a: append to log file instead of truncating
        -r: retrieve the experiment data at the end
        -d: destroy the network at the end (must have -r)
        -t: create experiment tags on a local grafana (localhost:3000)
        
        E.g.: python3 runtests.py -l log.log -o example.json
    ''')
    os._exit(1)

def date_string_to_datetime(date_str):
    date_format = "%Y%m%d.%H%M%S"
    date_obj = datetime.strptime(date_str, date_format)
    return date_obj

def explode(var):
    result = []
    for val in var['values']:
        result.append({
            'tmpl_file': var['tmpl_file'],
            'output_file': var['output_file'],
            'tag': var['tag'],
            'value': val})
    return result


def zip_variables(config):
    log.debug("Config: %s", config)
    exploded = [e for e in map(lambda var: explode(var), config['zip_vars'])]
    # TODO: check that all lists in exploded have the same length
    return list(map(list, zip(*exploded)))

def tag(begin, end, annotation):
    request_body = {
        #"dashboardUID":"", 
        "panelId":1, 
        "time":begin, 
        "timeEnd":end, 
        "tags":["untagged"], 
        "text":annotation
    }

    access_token = open(".grafana_token", "r").read().splitlines()[0]

    response = requests.post(
	url='http://localhost:3000/api/annotations', 
	headers={'Content-Type':'application/json',
                 'Authorization': 'Bearer {}'.format(access_token)},
        json=request_body)
    return response

def setup_shell(log_file):
    sh = pexpect.spawn(
        "/bin/sh", cwd=global_output_folder, timeout=None)
    sh.logfile = log_file

    sh.sendline(r"PS1='[PEXPECT]\$ '")  # In case of sh-style
    i = sh.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT], timeout=10)
    if i == 0:
        print("# Couldn't set sh-style prompt -- trying csh-style.")
        sh.sendline(r"set prompt='[PEXPECT]\$ '")
        i = sh.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT], timeout=10)
        if i == 0:
            print("Failed to set command prompt using sh or csh style.")
            print("Response was:")
            print(sh.before)
            sys.exit(1)

    sh.sendline('pwd')
    index = sh.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
    if index == 0:
        log.error('Timeout!!')
        exit()
    elif index == 1:
        log.info('Working directory')

    return sh

def main():

    # TODO: use argparse (https://docs.python.org/pt-br/3/library/argparse.html#module-argparse) instead?
 
    try:
        optlist, args = getopt.getopt(sys.argv[1:], 'hal:o:virts', [
                                      'help', 'append', 'log', 'options', 'interactive', 'retrieve', 'tag-experiments', 'single-pass'])
    except Exception as e:
        log.error("ERROR: %s", str(e))
        exit_with_usage()
    options = dict(optlist)

    log_filename = 'log.log'
    opt_filename = 'opt.json'
    append = True
    verbosity = 35
    interactive = False
    destroy = False
    retrieve = False
    tag_experiment = False
    single_pass = False

    for k, v in options.items():
        if k in ('-h', '--help'):
            print("Help:")
            exit_with_usage()
        elif k in ('-a', '--append'):
            append = True
        elif k in ('-l', '--log'):
            log_filename = v
            print(log_filename)
        elif k in ('-o', '--options'):
            opt_filename = v
            print(opt_filename)
        elif k in ('-v'):
            verbosity = verbosity - 10
            if verbosity < 5:
                verbosity = 5
        elif k in ('-i', '--interactive'):
            interactive = True
        elif k in ('-d', '--destroy'):
            destroy = True
        elif k in ('-r', '--retrieve'):
            retrieve = True
        elif k in ('-t', '--tag-experiments'):
            tag_experiment = True
        elif k in ('-s', '--single-pass'):
            single_pass = True
        else:
            assert False, 'unhandled option'

    if not retrieve and destroy:
        log.error(
            "Refusing to destroy the network without retrieving the experiment data")
        exit(2)

    # log.basicConfig(format="%(levelname)s: %(message)s", level=verbosity)
    log.basicConfig(format="%(levelname)s: %(message)s", level=log.INFO)

    if append:
        log_file = open(log_filename, "ab")
    else:
        log_file = open(log_filename, "wb")

    fopt = open(opt_filename, "r")

    # Interpret the options file.
    options = json.load(fopt)

    bash = setup_shell(log_file)

    for seq in options['sequences']:
        log.info("Sequence entry: %s", seq['name'])

        conf_names = list(
            map(lambda conf: conf['name'], seq['configurations']))
        log.info("Configurations: %s ", conf_names)

        # Zip the values of each configuration
        zipped_confs = list(map(zip_variables, seq['configurations']))
        log.debug("Zipped: %s", zipped_confs)

        # Combine the configurations in a sequence entry
        combined_confs = list(map(lambda conf: [
                              item for sublist in conf for item in sublist], itertools.product(*(zipped_confs))))
        log.debug("Combined: %s", combined_confs)

        # Iterate over the combined configurations, apply and execute them
        for conf in combined_confs:
            log.debug("Conf: %s", conf)
            # FIXME: assuming that same output_file implies tmpl_file
            # group options by input/output file

            def conf_key_function(x): return (
                x['tmpl_file'], x['output_file'])
            conf.sort(key=conf_key_function)

            annotation = ''

            for (t, o), g in itertools.groupby(conf, conf_key_function):
                log.info("Creating %s/%s from %s", global_output_folder, o, t)
                update_contents = None
                with open(t, 'r') as file:
                    updated_contents = file.read()

                for e in g:
                    log.info("Replacing %s for %s", e['tag'], str(e['value']))
                    annotation = annotation + "{} => {}\n".format(e['tag'], str(e['value']))
                    updated_contents = updated_contents.replace(
                        e['tag'], str(e['value']))

                with open(global_output_folder + '/' + o, 'w') as file:
                    file.write(updated_contents)
            

            if single_pass:
                input("First pass generating configuration files is done.")
                exit(0)

            if interactive:
                input("Configuration files generated.\nPress Enter to continue execution with them")

            ######################################################################
            # Assume network has been started but no experiments are being executed.
            # Execute the combinations and store the logs (specially timestamps)
            ######################################################################
            bash.sendline("make configgen")
            index = bash.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
            if index == 0:
                log.error('Timeout!!')
                exit()
            elif index == 1:
                log.info('Configurations updated')

            bash.sendline("make restart")
            index = bash.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
            if index == 0:
                log.error('Timeout!!')
                exit()
            elif index == 1:
                # FIXME: Check 'changed' counter.
                log.info('Restart completed')

            # Begin log with date/time in the form CCCCyymm.hhmmss
            begin_time = time.localtime()
            log_file.write(b'# Begin time: %4d%02d%02d.%02d%02d%02d \n' %
                           begin_time[:-3])
            log_file.write(annotation.encode())
            log_file.write("# Sequence entry: {}\n".format(
                seq['name']).encode())
            log.info("# Configuration: %s ", conf)

            bash.sendline("make runload")
            index = bash.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
            if index == 0:
                log.error('Timeout!!')
                exit()
            elif index == 1:
                log.info('Test concluded')

            # End log entry with date/time
            end_time = time.localtime()
            log_file.write(b'# End time: %4d%02d%02d.%02d%02d%02d \n' %
                           end_time[:-3])

            if tag_experiment:
                tag(begin_time, end_time, annotation) 

            if retrieve:
                bash.sendline("make retrieve-blockstore")
                index = bash.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
                if index == 0:
                   log.error('Timeout!!')
                   exit()
                elif index == 1:
                   log.info('Retrieved the blockstore')

            if interactive:
                input("Experiment ended.\nPress Enter to continue...")

    # Collect the prometheus database and associate with the log file.
    if retrieve:
        bash.sendline("make retrieve-prometheus-data")
        index = bash.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
        if index == 0:
             log.error('Timeout!!')
             exit()
        elif index == 1:
             log.info('Retrieved the prometheus data')

    # optionally destroy the network.
    if destroy:
        bash.sendline("make terraform-destroy")
        index = bash.expect([pexpect.TIMEOUT, 'Enter a value:'])
        if index == 0:
            log.error('Timeout!!')
            exit()
        elif index == 1:
            bash.sendline("yes")
            index = bash.expect([pexpect.TIMEOUT, global_COMMAND_PROMPT])
            if index == 0:
                log.error('Timeout!!')
                exit()
            elif index == 1:
                log.info('The network has been destroyed')

    log_file.close()
    return 0


if __name__ == "__main__":
    main()
