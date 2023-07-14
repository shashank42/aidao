import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import ExampleToken from "ExampleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import ExampleNFT from "ExampleNFT.cdc"
import InferenceNFT from "InferenceNFT.cdc"
// import FlowToken from 0x7e60df042a9c0868

pub contract MainContract { // NonFungibleToken.Receiver, NonFungibleToken.Provider

    // pub let FlowTokenVault: Capability<&ExampleToken.Vault{FungibleToken.Receiver}>

    // Structs
    pub struct Request {
        pub let start: UInt64
        // pub(set) var countInferences: UInt64
        pub let offer: UInt64
        pub let responder: Address
        // var paid: Bool
        pub let requestor: Address

        init(
            start : UInt64,
            // countInferences : UInt64,
            offer : UInt64,
            responder : Address,
            // paid : Bool,
            requestor : Address
        ) {
            self.start = start
            // self.countInferences = countInferences
            self.offer = offer
            self.responder = responder
            // self.paid = paid
            self.requestor = requestor
        }
    }

    pub struct Response {
        pub let url: String
        pub let responder: Address

        init(
            url : String,
            responder : Address,
        ) {
            self.url = url
            self.responder = responder
        }

    }

    pub struct Responder {
        pub(set) var active: Bool
        // pub(set) var countInferences: UInt64
        pub(set) var averageRating: UInt64
        pub(set) var countRating: UInt64
        pub(set) var cost: UInt64

        init(
            active : Bool,
            // countInferences : UInt64,
            averageRating : UInt64,
            countRating : UInt64,
            cost : UInt64
        ) {
            self.active = active
            // self.countInferences = countInferences
            self.averageRating = averageRating
            self.countRating = countRating
            self.cost = cost
            
        }

    }

    // // Constants
    pub let MAX_INFERENCES: UInt64
    pub var requestId: UInt64

    // // Fields
    pub var requests: {UInt64: Request}
    pub var staked: {Address: UInt64}
    pub var responses: {UInt64: [Response]}
    pub var responders: {Address: Responder}

    /// The event that is emitted when a new minter resource is created
    pub event RequestReceived(
            requestor: Address,
            requestId: UInt64,
            prompt: String,
            offer: UInt64,
            responder: Address
    )

    pub event ResponseReceived(
            requestId: UInt64,
            responder: Address,
            url: String
    )

    pub event ResponderAdded(
            responder: Address,
            cost: UInt64,
            tokenId: UInt64
    )

    pub event ResponderRemoved(
            responder: Address
    )


    // pub var token: @FungibleToken.Trait
    // pub var tokenSet: Bool
    // pub let RATING_REWARD: UInt64
    // pub var TIMEOUT: UInt64
    // pub var MIN_INFERENCES: UInt64
    // pub var nodeAddress: Address
    // pub var nodeAddressSet: Bool

    // pub fun deposit(tokenValue: UFix64) {
    //     token.deposit(from: /storage/flowTokenVault, amount: tokenValue)
    // }

    // pub fun withdraw(tokenValue: UFix64) {
    //     token.withdraw(from: /storage/flowTokenVault, amount: tokenValue)
    // }


    init() {
        self.MAX_INFERENCES = 10
        self.requestId = 0

        self.requests = {}
        self.staked = {}
        self.responses = {}
        self.responders = {}

        // self.MIN_INFERENCES = 10
        // self.nodeAddressSet = false
        // self.nodeAddress = 0x0
        
        // self.RATING_REWARD = 5
        
        // self.tokenSet = false
        // self.TIMEOUT = 86400

        // create a public capability for the collection
        // self.account.link<&RedSquirrelNFT.Collection{NonFungibleToken.CollectionPublic, RedSquirrelNFT.RedSquirrelNFTCollectionPublic}>(
        //     self.CollectionPublicPath,
        //     target: self.CollectionStoragePath
        // )

        // self.account.link<&ExampleToken.Vault{FungibleToken.Provider}>(
        //     ExampleToken.VaultPublicPath,
        //     target: ExampleToken.VaultStoragePath
        // )
    }

    // pub fun setUpRecieverVault(FlowTokenVault: Capability<&ExampleToken.Vault{FungibleToken.Receiver}>) {
    //     self.FlowTokenVault = FlowTokenVault;
    // }

    // pub fun setupToken(tokenAddress: Address) {
    //     self.token = getAccount(tokenAddress)
    //     self.tokenSet = true
    // }

    // pub fun setupNodeAddress(nodeAddress: Address) {
    //     self.nodeAddress = nodeAddress
    //     self.nodeAddressSet = true
    // }

    pub fun requestInference(
        prompt: String, 
        requestor: Address, 
        responder: Address, 
        offer: UInt64,
        requestorVault: @ExampleToken.Vault,
        receiverCapability: &{FungibleToken.Receiver}
    ) {

        pre {
            requestorVault.balance == UFix64(offer): "Payment is not equal to the price of NFT"
        }
        
        let request = Request(
            start: getCurrentBlock().height,
            // countInferences: 0,
            offer: UInt64(requestorVault.balance),
            responder: responder,
            // paid: false,
            requestor: requestor
        )

        receiverCapability.deposit(from: <- requestorVault)

        if (self.staked[requestor] == nil) {
            self.staked[requestor] = UInt64(0)
        }
        self.staked[requestor] = self.staked[requestor]! + UInt64(offer)


        self.requests[self.requestId] = request
        
        if (self.staked[requestor] == nil) {
            self.staked[requestor] = UInt64(0)
        }

        emit RequestReceived(
            requestor: requestor,                          
            requestId: self.requestId,
            prompt: prompt,
            offer: UInt64(offer),
            responder: responder
        )
        self.requestId = self.requestId + 1

        
    }


    pub fun recieveInference(
        id: UInt64, 
        url: String, 
        responder: Address,
        tokenProvider: Capability<&ExampleToken.Vault>,
        responderRecievingCapability: &{FungibleToken.Receiver},
        responderNFTRecievingCapability: &{NonFungibleToken.CollectionPublic},
        minter: &InferenceNFT.NFTMinter
        ) {

        // escrowVault: @ExampleToken.Vault,
        // tokenProvider: &{FungibleToken.Provider},

        if let responder = self.responders[responder] {
            assert(responder.active, message: "Responder inactive")
        } else {
            panic("Responder not registered")
        }

        if let request = self.requests[id] {
            // assert(request.start > 0, message: "Request inexistent")
            // assert(request.countInferences < MAX_INFERENCES, message: "Max inferences reached")

            // if let requestResponder = request.responder {
            //     assert(requestResponder == responder, message: "Incorrect responder")
            // }

            // if let responder = responders[responder] {
            //     assert(responder.cost <= request.offer, message: "Insufficient offer")
            // }

            if (self.responses[id] == nil) {
                self.responses[id] = []
            }
            self.responses[id]?.append(self.Response(url: url, responder: responder))

            // self.requests[id]?.countInferences = self.requests[id]?.countInferences! + UInt64(1)
            // responders[responder]?.countInferences = responders[responder]?.countInferences + 1


            responderRecievingCapability.deposit(from: <- tokenProvider.borrow()!.withdraw(amount: UFix64(1)))

            // responderRecievingCapability.deposit(from: <- escrowVault)

            minter.mintNFT(
                recipient: responderNFTRecievingCapability,
                name: "BLABLA",
                description: "HELLO",
                thumbnail: "WOW",
                royalties: [] as [MetadataViews.Royalty]
            )

    
            // Reduce the staked amount
            self.staked[request.requestor]      =  self.staked[request.requestor]! - request.offer

            emit self.ResponseReceived(requestId: self.requestId, responder: responder, url: url)
        } else {
            panic("Request not found")
        }
    }

    // pub fun withdrawRequest(id: UInt64) {
    //     if let request = requests[id] {
    //         assert(request.start > 0, message: "Request inexistent")
    //         assert(request.requestor == getTransactionSource(), message: "Not the requestor")
    //         assert(request.start + TIMEOUT < getCurrentBlock().height, message: "Timeout")

    //         withdraw(tokenValue: requests[id].offer)
    //         staked[getTransactionSource()] = staked[getTransactionSource()] - requests[id].offer

    //         destroy requests[id]
    //     } else {
    //         panic("Request not found")
    //     }
    // }

    pub fun registerResponder(
        cost: UInt64, 
        url: String, 
        responder: Address,
        recipient: &{NonFungibleToken.CollectionPublic},
        name: String,
        description: String,
        thumbnail: String,
        minter: &ExampleNFT.NFTMinter
        ) {

        self.responders[responder] = Responder(
            active: true,
            // countInferences: 0,
            averageRating: 0,
            countRating: 0,
            cost: UInt64(cost)
        )

        var tokenId = minter!.mintNFT(
            recipient: recipient,
            name: name,
            description: description,
            thumbnail: thumbnail,
            royalties: [] as [MetadataViews.Royalty]
        )

        emit ResponderAdded(responder: responder, cost: UInt64(cost), tokenId: tokenId)

    }

    pub fun removeResponder(responder: Address) {
        // self.responders[responder]?.active = false
        // @todo add destroy nft here
        emit ResponderRemoved(responder: responder)
    }

    // pub fun rateInference(id: UInt64, inferenceId: UInt64, rating: UInt64) {
    //     if let responseArray = responses[id] {
    //         assert(responseArray.count >= inferenceId, message: "Inference inexistent")
    //         assert(rating > 0 && rating < 10, message: "Between 1 and 10")

    //         // Scale rating by 1000
    //         let scaledRating = rating * 1000

    //         let responder = responses[id][inferenceId].responder

    //         if let responderData = responders[responder] {
    //             let newAverageRating = (
    //                 responderData.averageRating * responderData.countRating + scaledRating
    //             ) / (responderData.countRating + 1)

    //             responders[responder] = Responder(
    //                 active: responderData.active,
    //                 countInferences: responderData.countInferences,
    //                 averageRating: newAverageRating,
    //                 countRating: responderData.countRating + 1,
    //                 cost: responderData.cost
    //             )
    //         } else {
    //             panic("Responder not found")
    //         }

    //         deposit(tokenValue: RATING_REWARD)
    //         emit RatingReceived(
    //             requestId: id,
    //             inferenceId: inferenceId,
    //             responder: responder,
    //             rater: getTransactionSource(),
    //             rating: rating
    //         )
    //     } else {
    //         panic("Response not found")
    //     }
    // }

    // // Implement NonFungibleToken.Receiver
    // pub fun onNonFungibleTokenSent(id: UInt64, data: [UInt8]): UFix64 {
    //     return UFix64(0.0)
    // }

    // // Implement NonFungibleToken.Provider
    // pub fun addressesApprovedFor(tokenID: UInt64): [Address] {
    //     return []
    // }


    



}