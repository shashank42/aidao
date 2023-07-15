// This script reads the balance field
// of an account's ExampleToken Balance

import MainContract from "MainContract"

pub fun main(address: Address): UInt64? {
    // let account = getAccount(address)
    // let vaultRef = account.getCapability(ExampleToken.VaultPublicPath)
    //     .borrow<&ExampleToken.Vault{FungibleToken.Balance}>()
    //     ?? panic("Could not borrow Balance reference to the Vault")

    return MainContract.getStakedOf(address: address)
}