import os
import time
from web3 import Web3
from dotenv import load_dotenv

load_dotenv()

TWELVE_HOURS = 12 * 60 * 60

MAINNET_PROVIDER = Web3(Web3.HTTPProvider(os.getenv("MAINNET_RPC_URL")))
ARBITRUM_PROVIDER = Web3(Web3.HTTPProvider(os.getenv("ARBITRUM_RPC_URL")))
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
ACCOUNT = MAINNET_PROVIDER.eth.account.from_key(PRIVATE_KEY)
ACCOUNT_ADDRESS = ACCOUNT.address

price_feed_abi = [
    {"constant": True, "inputs": [], "name": "latestTimestamp", "outputs": [{"name": "", "type": "uint256"}], "payable": False, "stateMutability": "view", "type": "function"},
    {"constant": False, "inputs": [{"name": "targetChain", "type": "uint16"}, {"name": "targetAddress", "type": "address"}], "name": "syncRate", "outputs": [], "payable": True, "stateMutability": "payable", "type": "function"},
    {"constant": True, "inputs": [{"name": "targetChain", "type": "uint16"}], "name": "quoteRateSync", "outputs": [{"name": "cost", "type": "uint256"}], "payable": False, "stateMutability": "view", "type": "function"},
]

price_feed_address = Web3.to_checksum_address(os.getenv("PRICE_FEED"))  # Mainnet
price_feed_sender_address = Web3.to_checksum_address(os.getenv("PRICE_FEED_SENDER"))  # Mainnet
target_chain = int(os.getenv("TARGET_CHAIN"))
target_address = Web3.to_checksum_address(os.getenv("TARGET_ADDRESS"))  # Arbitrum

def check_and_sync():
    price_feed = MAINNET_PROVIDER.eth.contract(address=price_feed_address, abi=price_feed_abi)
    price_feed_sender = MAINNET_PROVIDER.eth.contract(address=price_feed_sender_address, abi=price_feed_abi)

    # Step 1: Check latest timestamp
    latest_timestamp = price_feed.functions.latestTimestamp().call()
    current_time = int(time.time())

    if current_time - latest_timestamp < TWELVE_HOURS:
        print("Less than 12 hours since the last update. No action needed.")
        return

    # Step 2: Get the cost
    current_rate = price_feed_sender.functions.quoteRateSync(target_chain).call()

    # Step 3: Sync the rate
    tx = price_feed_sender.functions.syncRate(target_chain, target_address).build_transaction({
        'chainId': 1,  # Mainnet
        'gas': 200000,
        'gasPrice': Web3.to_wei('20', 'gwei'),
        'nonce': MAINNET_PROVIDER.eth.get_transaction_count(ACCOUNT.address),
        'value': current_rate
    })

    signed_tx = ACCOUNT.sign_transaction(tx)
    tx_hash = MAINNET_PROVIDER.eth.send_raw_transaction(signed_tx.rawTransaction)

    print(f"Sync transaction sent: {tx_hash.hex()}")
    receipt = MAINNET_PROVIDER.eth.wait_for_transaction_receipt(tx_hash)
    print("Sync transaction confirmed.")

if __name__ == "__main__":
    try:
        check_and_sync()
    except Exception as e:
        print(f"Error in check_and_sync: {e}")
        exit(1)
