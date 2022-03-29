
import subprocess
import uuid
import os
import logging
import sys
import json

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


def lambda_handler(event, context):
    if event.get('log_event', False):
        logger.debug("Input event: {}".format(json.dumps(event)))

    cmd = event['interpreter']
    if event['command'] is not None:
        # Create a unique file for the script to be temporarily stored in
        scriptpath = "/tmp/lambda-shell-{}".format(uuid.uuid1())
        with open(scriptpath, "x") as f:
            # Write the script to the file
            f.write(event['command'])
        cmd.append(scriptpath)

    # Run the command as a subprocess
    if event.get('log_event', False):
        logger.info("Running command: {}".format(cmd))

    # For the subprocess environment, use all of the existing env vars, plus
    # any new ones. New ones with the same name will overwrite.
    new_env = os.environ.copy()
    # Set the python path to include everything that is given by default to Python functions
    new_env['PYTHONPATH'] = ':'.join(sys.path)
    new_env.update(event['environment'])

    # Start the process
    p = subprocess.Popen(
        cmd, shell=False, env=new_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    timed_out = False
    try:
        # If timeout is None, this will wait forever
        p.wait(event['timeout'])
    except subprocess.TimeoutExpired:
        # If it timed out, kill it
        p.kill()
        timed_out = True

    # Read the stdout, stderr and exit code
    stdout, stderr = p.communicate()
    stdout = stdout.decode('utf-8')
    stderr = stderr.decode('utf-8')
    exit_code = p.returncode

    # Delete the command file if we created one
    if event['command'] is not None:
        os.remove(scriptpath)

    if timed_out:
        # If it timed out
        if event['fail_on_timeout']:
            # And we want to fail on a timeout, then throw an error
            raise subprocess.SubprocessError('''Lambda Shell command timed out after {} seconds.
Stdout: 
{}

Stderr:
{}
'''.format(event['timeout'], stdout, stderr))
        else:
            # And set the exit code to 0 so we don't fail for a bad exit code
            exit_code = 0

    # If the exit code was non-zero and we want to fail on a non-zero exit code, OR
    # there was stderr output and we want to fail on stderr, then raise an error
    if (exit_code != 0 and event['fail_on_nonzero_exit_code']) or (len(stderr) > 0 and event['fail_on_stderr']):
        if timed_out:
            # If it timed out, prepend a timeout message to the stderr
            stderr = 'TIMEOUT after {} seconds.\n{}'.format(
                event['timeout'], stderr)
        # Throw the error
        raise subprocess.SubprocessError('''Lambda Shell command failed.
Exit code: 
{}

Stdout: 
{}

Stderr:
{}
'''.format(exit_code, stdout, stderr))

    logger.debug("Exit code: {}".format(exit_code))
    logger.debug("Stdout {}".format(stdout))
    logger.debug("Stderr {}".format(stderr))
    return {
        'exit_code': exit_code,
        'stdout': stdout,
        'stderr': stderr
    }
