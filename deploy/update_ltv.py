import json
import os
import time
import logging
from eth_account import Account
from eth_typing import ChecksumAddress
from gql import gql, Client
from gql.transport.requests import RequestsHTTPTransport
from web3 import Web3
from dotenv import load_dotenv
from web3.contract import Contract
from web3.middleware import construct_sign_and_send_raw_middleware

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

EXECUTION_ENDPOINT = os.getenv('EXECUTION_ENDPOINT')
PRIVATE_KEY = os.getenv('PRIVATE_KEY')
VAULT_USER_LTV_TRACKER_CONTRACT_ADDRESS = Web3.to_checksum_address(os.getenv('VAULT_USER_LTV_TRACKER_CONTRACT_ADDRESS'))
GRAPH_API_URL = os.getenv('GRAPH_API_URL')
GRAPH_API_TIMEOUT = int(os.getenv('GRAPH_API_TIMEOUT', default=10))
VAULT = Web3.to_checksum_address(os.getenv('VAULT'))

account = Account.from_key(PRIVATE_KEY)
web3 = Web3(Web3.HTTPProvider(EXECUTION_ENDPOINT))
web3.middleware_onion.add(construct_sign_and_send_raw_middleware(account))


def get_vault_user_ltv_tracker_contract() -> Contract:
    with open('abi/IVaultUserLtvTracker.json') as f:
        abi = json.load(f)

    return web3.eth.contract(
        address=VAULT_USER_LTV_TRACKER_CONTRACT_ADDRESS,
        abi=abi,
    )


def update_vault_max_ltv_user() -> None:
    tracker_contract = get_vault_user_ltv_tracker_contract()

    # Get max LTV for vault
    user = graph_get_vault_max_ltv_allocator(VAULT)
    if user is None:
        logger.warning('No allocators in vault')
        return

    harvest_params = get_harvest_params(VAULT)

    # Update LTV
    tx = tracker_contract.functions.updateVaultMaxLtvUser(
        VAULT, user, harvest_params
    ).transact({
        'from': account.address
    })
    logger.info(f'updateVaultMaxLtvUser transaction sent: {tx.hex()}')

    # Wait for tx receipt
    receipt = web3.eth.wait_for_transaction_receipt(tx)

    # Check receipt status
    if not receipt.status:
        raise RuntimeError(f'updateVaultMaxLtvUser tx failed, tx hash: {tx.hex()}')

    logger.info('Sync transaction confirmed.')


def graph_get_vault_max_ltv_allocator(vault_address: str) -> ChecksumAddress | None:
    graph_client = get_graph_client()

    query = gql(
        """
        query AllocatorsQuery($vault: String) {
          allocators(
            first: 1
            orderBy: ltv
            orderDirection: desc
            where: { vault: $vault }
          ) {
            address
          }
        }
        """
    )
    params = {
        'vault': vault_address.lower(),
    }

    allocators = graph_client.execute(query, params)['allocators']

    if not allocators:
        return None

    return Web3.to_checksum_address(allocators[0]['address'])


def get_graph_client() -> Client:
    transport = RequestsHTTPTransport(
        url=GRAPH_API_URL,
        timeout=GRAPH_API_TIMEOUT,
    )
    return Client(transport=transport)


if __name__ == '__main__':
    update_vault_max_ltv_user()
