// This transaction is a template for a transaction to allow
// anyone to add a Vault resource to their account so that
// they can use the exampleToken

import FungibleToken from "FungibleToken"
import ExampleToken from "ExampleToken"
import MetadataViews from "MetadataViews"
import MainContract from "MainContract"

transaction () {
    let vault: Capability<&ExampleToken.Vault{FungibleToken.Receiver}>
    prepare(signer: AuthAccount){
        self.vault = signer.getCapability<&ExampleToken.Vault{FungibleToken.Receiver}>(ExampleToken.ReceiverPublicPath)
    } execute{
        MainContract.setUpRecieverVault(
            requestorVault: vault
        )
    }
}