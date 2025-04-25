import logging
import watchtower
import boto3
import json

debug = False

class LoggingService:
    def __init__(self, config: str):
        cfDict = read_config(config)
        log_group_name = cfDict.get('log_group_name', 'NOS-Sandbox-Logs')
        local_log_name = cfDict.get('local_log_name', 'log')
        log_level = logging.DEBUG # read this from cfDict.get('log_level', logging.DEBUG) <- interpret
        self.logger = logging.getLogger(local_log_name)
        self.logger.setLevel(log_level)

        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        console_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)

        # CloudWatch handler
        cloudwatch_handler = watchtower.CloudWatchLogHandler(
            boto3_session=boto3.Session(),
            log_group=log_group_name
        )
        cloudwatch_handler.setLevel(log_level)
        cloudwatch_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        cloudwatch_handler.setFormatter(cloudwatch_formatter)
        self.logger.addHandler(cloudwatch_handler)

    def get_logger(self):
        return self.logger
    
def readConfig(configfile) -> dict:
    """ Copied from ScratchDisk.py 
      Reads a JSON configuration file into a dictionary.

    Parameters
    ----------
    configfile : str
      Full path and filename of a JSON configuration file for this cluster.

    Returns
    -------
    cfDict : dict
      Dictionary containing this cluster parameterized settings.
    """

    with open(configfile, 'r') as cf:
        cfDict = json.load(cf)

    if debug:
        print(json.dumps(cfDict, indent=4))
        print(str(cfDict))

    # Single responsibility says I should only read it here
    return cfDict
