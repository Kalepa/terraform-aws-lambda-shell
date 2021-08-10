import subprocess
import uuid
import os

import logging

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    logger.debug("Input event: {}".format(event))

    # If a special flag is set, skip the execution
    if '__IL_TF_LS_SKIP_RUN' in event:
        return {}

    cmd = event['interpreter']
    if event['command'] is not None:
        # Create a unique file for the script to be temporarily stored in
        scriptpath = "/tmp/botoform-{}".format(uuid.uuid1())
        f = open(scriptpath, "x")
        # Write the script to the file
        f.write(event['command'])
        f.close()
        cmd.append(scriptpath)

    # Run the command as a subprocess
    logger.info("Running command: {}".format(cmd))
    result = subprocess.run(cmd, shell=False, capture_output=True)

    logger.debug("Result: {}".format(result))

    if event['command'] is not None:
        os.remove(scriptpath)

    stdout = result.stdout.decode('utf-8')
    stderr = result.stderr.decode('utf-8')
    if result.returncode != 0 and event['fail_on_error']:
        raise subprocess.SubprocessError(
            "Command returned non-zero exit code ({}) with stdout '{}' and stderr '{}'".format(result.returncode, stdout, stderr))

    return {
        'exitstatus': result.returncode,
        'stdout': stdout,
        'stderr': stderr
    }
