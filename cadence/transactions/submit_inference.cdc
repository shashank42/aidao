
// import FlowTransferNFT from 0x1b25a8536e63a7da
// import NonFungibleToken from 0x631e88ae7f1d7c20
// import MetadataViews from 0x631e88ae7f1d7c20
import MainContract from 0xf8d6e0586b0a20c7
import ExampleToken from 0xf8d6e0586b0a20c7
import FungibleToken from "FungibleToken"
import ExampleNFT from "ExampleNFT"
import NonFungibleToken from "NonFungibleToken"
import InferenceNFT from "InferenceNFT"

transaction(id: UInt64){ //type: String, url: String

    // The Vault resource that holds the tokens that are being transferred
    // let reciever: @ExampleToken.Vault
    let vault: Capability //<&ExampleToken.Vault{FungibleToken.Receiver}>
    /// Reference to the Fungible Token Receiver of the recipient
    // let tokenProvider: &{FungibleToken.Provider}
    let tokenReciever: &{FungibleToken.Receiver}
    let NFTRecievingCapability: &{NonFungibleToken.CollectionPublic}
    let minter: &InferenceNFT.NFTMinter

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

        self.NFTRecievingCapability = getAccount(signer.address).getCapability(InferenceNFT.CollectionPublicPath) 
                        .borrow<&InferenceNFT.Collection{NonFungibleToken.CollectionPublic}>()
                        ?? panic("Failed to get User's collection.")

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&InferenceNFT.NFTMinter>(from: InferenceNFT.MinterStoragePath)
            ?? panic("Account does not store an object at the specified path")

    }
    execute{

        MainContract.recieveInference(
        id: 0, 
        url: "Blabla", 
        responder: 0xf8d6e0586b0a20c7,
        tokenProvider: self.senderVault,
        responderRecievingCapability: self.tokenReciever,
        responderNFTRecievingCapability: self.NFTRecievingCapability,
        minter:  self.minter
        )

    }
}

