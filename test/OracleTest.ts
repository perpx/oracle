import {
    Account,
    StarknetContract,
    StarknetContractFactory,
    StringMap,
} from 'hardhat/types/runtime'
import { expect } from 'chai'
import { starknet } from 'hardhat'
import { Test } from 'mocha'
import { InvokeOptions } from '@shardlabs/starknet-hardhat-plugin/dist/src/types'

let contract: StarknetContract

let ownerAddress: bigint
let ownerAccount: Account

let newOwnerAddress: bigint
let newOwnerAccount: Account

let ownerDiff: boolean = false

before(async () => {
    const contractFactory: StarknetContractFactory =
        await starknet.getContractFactory('oracle.cairo')
    // Owner Account
    const add =
        '0x18986dd1cbceaa12be8d66da46a99146c6db79ff964a716ec556a8a9659be35'
    const key = '0x9d8d3ba9345f6d9c2c4c94040a50a9bf'
    ownerAddress = BigInt(add)
    ownerAccount = await starknet.getAccountFromAddress(
        add,
        key,
        'OpenZeppelin'
    )

    // New owner account
    const newAdd =
        '0x7367e8bbc2b0065ac566e1785b7480ce74d27cb360dabaf5c558deab7a2bb05'
    const newKey = '0xf93d163196bc5d67fa24da4ebaf84eb'
    newOwnerAddress = BigInt(newAdd)
    newOwnerAccount = await starknet.getAccountFromAddress(
        newAdd,
        newKey,
        'OpenZeppelin'
    )

    // Deploy
    const args: StringMap = {
        address: ownerAddress,
    }
    contract = await contractFactory.deploy(args)
})

beforeEach(async () => {
    if (ownerDiff) {
        const args: StringMap = {
            new_owner: ownerAddress,
        }
        await newOwnerAccount.invoke(contract, 'update_owner', args)
        ownerDiff = false
    }
})

describe('#view_owner', () => {
    it('should return the owner', async () => {
        const args: StringMap = {}
        const resp = await contract.call('view_owner', args)
        expect(resp.owner).to.equal(ownerAddress)
    })
})

describe('#update_owner', () => {
    it('should fail with new owner cannot be zero address', async () => {
        const args: StringMap = {
            new_owner: BigInt(0),
        }
        try {
            await contract.invoke('update_owner', args)
        } catch (error: any) {
            expect(error.message).to.contain(
                'new owner cannot be the zero address'
            )
        }
    })

    it('should fail with only current owner can update', async () => {
        const args: StringMap = {
            new_owner: newOwnerAddress,
        }
        try {
            await newOwnerAccount.invoke(contract, 'update_owner', args)
        } catch (error: any) {
            expect(error.message).to.contain('only current owner can update')
        }
    })

    it('should pass and update contract owner', async () => {
        const args: StringMap = {
            new_owner: newOwnerAddress,
        }
        const txHash = await ownerAccount.invoke(contract, 'update_owner', args)
        const receipt = await starknet.getTransactionReceipt(txHash)
        const events = await contract.decodeEvents(receipt.events)
        expect(events).to.deep.equal([
            {
                name: 'OwnerUpdate',
                data: {
                    owner: newOwnerAddress,
                },
            },
        ])

        const resp = await contract.call('view_owner')
        expect(resp.owner).to.equal(newOwnerAddress)
        ownerDiff = true
    })
})

describe('#get_measurement', () => {
    it('should return an empty measurement', async () => {
        const args: StringMap = {
            key: BigInt(1),
        }
        const resp = await contract.call('get_measurement', args)
        expect(resp.measurement.value).to.equal(0n)
        expect(resp.measurement.timestamp).to.equal(0n)
    })
})

describe('#set_measurement', () => {
    it('should fail with only current owner can update', async () => {
        const args: StringMap = {
            key: BigInt(1),
            measurement: {
                value: BigInt(12345),
                timestamp: BigInt(11111),
            },
        }
        try {
            const resp = await newOwnerAccount.invoke(
                contract,
                'set_measurement',
                args
            )
        } catch (error: any) {
            expect(error.message).to.contain('only current owner can update')
        }
    })

    it('should pass, update measurement and emit MeasurementUpdate', async () => {
        const args: StringMap = {
            key: BigInt(1),
            measurement: {
                value: BigInt(12345),
                timestamp: BigInt(11111),
            },
        }
        const txHash = await ownerAccount.invoke(
            contract,
            'set_measurement',
            args
        )
        const receipt = await starknet.getTransactionReceipt(txHash)
        const events = await contract.decodeEvents(receipt.events)
        expect(events).to.deep.equal([
            {
                name: 'MeasurementUpdate',
                data: {
                    key: 1n,
                    measurement: {
                        value: 12345n,
                        timestamp: 11111n,
                    },
                },
            },
        ])

        const a: StringMap = {
            key: BigInt(1),
        }
        const resp = await contract.call('get_measurement', a)
        expect(resp.measurement.value).to.equal(12345n)
        expect(resp.measurement.timestamp).to.equal(11111n)
    })
})
