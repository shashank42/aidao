
// import FlowTransferNFT from 0x1b25a8536e63a7da
// import NonFungibleToken from 0x631e88ae7f1d7c20
// import MetadataViews from 0x631e88ae7f1d7c20
import MainContract from 0xf8d6e0586b0a20c7
import ExampleToken from 0xf8d6e0586b0a20c7
import FungibleToken from "FungibleToken"
import ExampleNFT from "ExampleNFT"
import NonFungibleToken from "NonFungibleToken"
import InferenceNFT from "InferenceNFT"

transaction(){ //type: String, url: String

    // The Vault resource that holds the tokens that are being transferred
    // let reciever: @ExampleToken.Vault
    let vault: Capability //<&ExampleToken.Vault{FungibleToken.Receiver}>
    /// Reference to the Fungible Token Receiver of the recipient
    // let tokenProvider: &{FungibleToken.Provider}
    let tokenReciever: &{FungibleToken.Receiver}
    let NFTRecievingCapability: &{NonFungibleToken.CollectionPublic}
    let minter: &ExampleNFT.NFTMinter

    let senderVault: Capability<&ExampleToken.Vault>

    prepare(signer: AuthAccount){

        // self.sender <- signer.borrow<&ExampleToken.Vault>(from: ExampleToken.VaultStoragePath)!.withdraw(amount: UFix64(1)) as! @ExampleToken.Vault

        // Get the account of the recipient and borrow a reference to their receiver
        var account = getAccount(0xf8d6e0586b0a20c7)
        // self.tokenProvider = account
        //     .getCapability(ExampleToken.VaultStoragePath)
        //     .borrow<&{FungibleToken.Provider}>()
        //     ?? panic("Unable to borrow provider reference")

        self.senderVault = signer.getCapability<&ExampleToken.Vault>(/private/exampleTokenVault)


        self.tokenReciever = account
            .getCapability(ExampleToken.ReceiverPublicPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")

        self.vault = signer.getCapability(ExampleToken.ReceiverPublicPath)

        self.NFTRecievingCapability = getAccount(signer.address).getCapability(ExampleNFT.CollectionPublicPath) 
                        .borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>()
                        ?? panic("Failed to get User's collection.")

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.MinterStoragePath)
            ?? panic("Account does not store an object at the specified path")

    }
    execute{
        MainContract.registerResponder(
            cost: 1, 
            url: "blabla", 
            responder: 0xf8d6e0586b0a20c7,
            recipient: self.NFTRecievingCapability,
            name: "BLABLA",
            description: "BLABLA",
            thumbnail: "BlaBla",
            minter: self.minter
        )

    }
}

