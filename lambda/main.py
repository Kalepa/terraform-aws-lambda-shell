import subprocess
import uuid
import os

import logging

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    logger.debug("Input event: {}".format(event))

    cmd = event['interpreter']
    if event['command'] is not None:
        # Create a unique file for the script to be temporarily stored in
        scriptpath = "/tmp/lambda-shell-{}".format(uuid.uuid1())
        with open(scriptpath, "x") as f:
            # Write the script to the file
            f.write(event['command'])
        cmd.append(scriptpath)

    # Run the command as a subprocess
    logger.info("Running command: {}".format(cmd))
    result = subprocess.run(cmd, shell=False, capture_output=True)

    logger.debug("Result: {}".format(result))

    if event['command'] is not None:
        os.remove(scriptpath)

    stdout = result.stdout.decode('utf-8')
    stderr = result.stderr.decode('utf-8')
    if (result.returncode != 0 and event['fail_on_nonzero_exit_code']) or (len(result.stderr) > 0 and event['fail_on_stderr']):
        raise subprocess.SubprocessError('''Lambda Shell command failed.
Exit code: 
{}

Stdout: 
{}

Stderr:
{}
'''.format(result.returncode, stdout, stderr))

    return {
        'exit_code': result.returncode,
        'stdout': stdout,
        'stderr': stderr
    }
