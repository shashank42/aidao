import FungibleToken from "FungibleToken"
import NonFungibleToken from "NonFungibleToken"
import ExampleToken from "ExampleToken"
import MetadataViews from "MetadataViews"
import ExampleNFT from "ExampleNFT"
import InferenceNFT from "InferenceNFT"
// import FlowToken from 0x7e60df042a9c0868

pub contract MainContract { // NonFungibleToken.Receiver, NonFungibleToken.Provider

    // pub let FlowTokenVault: Capability<&ExampleToken.Vault{FungibleToken.Receiver}>

    // Structs
    pub struct Request {
        pub let start: UInt64
        pub let offer: UInt64
        pub let responder: Address
        pub let requestor: Address

        init(
            start : UInt64,
            offer : UInt64,
            responder : Address,
            requestor : Address
        ) {
            self.start = start
            self.offer = offer
            self.responder = responder
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
        pub(set) var averageRating: UInt64
        pub(set) var countRating: UInt64
        pub(set) var cost: UInt64

        init(
            active : Bool,
            averageRating : UInt64,
            countRating : UInt64,
            cost : UInt64
        ) {
            self.active = active
            self.averageRating = averageRating
            self.countRating = countRating
            self.cost = cost   
        }
    }

    pub struct Rating {
        pub(set) var rating: UInt64
        pub(set) var rater: Address

        init(
            rating : UInt64,
            rater : Address,
        ) {
            self.rating = rating
            self.rater = rater
        }
    }


    // // Constants
    pub var requestId: UInt64

    // // Fields
    pub var requests: {UInt64: Request}
    pub var staked: {Address: UInt64}
    pub var responses: {UInt64: Response}
    pub var responders: {Address: Responder}
    pub var ratings: {UInt64: Rating}

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


    pub event RatingReceived(
            requestId: UInt64,
            responder: Address,
            rater: Address,
            rating: UInt64
    )

    pub let RATING_REWARD: UInt64

    init() {
        self.requestId = 0

        self.requests = {}
        self.staked = {}
        self.responses = {}
        self.responders = {}
        self.ratings = {}
        
        self.RATING_REWARD = UInt64(5.0)

    }

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
            offer: UInt64(requestorVault.balance),
            responder: responder,
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

        if let responderData = self.responders[responder] {
            assert(responderData.active, message: "Responder inactive")
            if let request = self.requests[id] {

                assert(request.responder == responder, message: "Incorrect responder")
                assert(request.offer <= responderData.cost, message: "Insufficient offer")

                self.responses[id] = self.Response(url: url, responder: responder)
                responderRecievingCapability.deposit(from: <- tokenProvider.borrow()!.withdraw(amount: UFix64(1)))
                minter.mintNFT(
                    recipient: responderNFTRecievingCapability,
                    name: "BLABLA",
                    description: "HELLO",
                    thumbnail: "WOW",
                    royalties: [] as [MetadataViews.Royalty]
                )

                // Reduce the staked amount
                self.staked[request.requestor] = self.staked[request.requestor]! - request.offer
                emit self.ResponseReceived(requestId: self.requestId, responder: responder, url: url)

            } else {
                panic("Request not found")
            }
        } else {
            panic("Responder not registered")
        }

        
    }

    // pub fun withdrawRequest(id: UInt64) {
    //     if let request = self.requests[id] {
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
        if let responderData = self.responders[responder] {
            self.responders[responder] = Responder(
                active: false,
                averageRating: responderData.averageRating,
                countRating: responderData.countRating,
                cost: responderData.cost
            )
        } else {
            panic("Responder not found")
        }
        // @todo add destroy nft here
        emit ResponderRemoved(responder: responder)
    }

    pub fun rateInference(
        id: UInt64, 
        rating: UInt64,
        minter: &ExampleToken.Minter,
        receiverCapability: &{FungibleToken.Receiver},
        rater: Address
        ) {

        if let response = self.responses[id] {
            assert(rating > 0 && rating < 10, message: "Between 1 and 10")

            // Scale rating by 1000
            let scaledRating = rating * 1000
            let responder = response.responder

            self.ratings[id] = Rating(rating: scaledRating, rater: rater)

            if let responderData = self.responders[responder] {
                let newAverageRating = (
                    responderData.averageRating * responderData.countRating + scaledRating
                ) / (responderData.countRating + 1)

                self.responders[responder] = Responder(
                    active: responderData.active,
                    // countInferences: responderData.countInferences,
                    averageRating: newAverageRating,
                    countRating: responderData.countRating + 1,
                    cost: responderData.cost
                )
            } else {
                panic("Responder not found")
            }

             // Create a minter and mint tokens
            let mintedVault <- minter.mintTokens(amount: UFix64(self.RATING_REWARD))

            // Deposit them to the receiever
            receiverCapability.deposit(from: <-mintedVault)

            emit RatingReceived(
                requestId: id,
                responder: responder,
                rater: rater,
                rating: rating
            )
        } else {
            panic("Response not found")
        }
    }

    // // Implement NonFungibleToken.Receiver
    // pub fun onNonFungibleTokenSent(id: UInt64, data: [UInt8]): UFix64 {
    //     return UFix64(0.0)
    // }

    // // Implement NonFungibleToken.Provider
    // pub fun addressesApprovedFor(tokenID: UInt64): [Address] {
    //     return []
    // }

    // Bunch of get functions
    pub fun getResponders(): {Address: Responder} {
        return self.responders
    }

    pub fun getRequests(): {UInt64: Request} {
        return self.requests
    }

    pub fun getResponses(): {UInt64: Response} {
        return self.responses
    }

    pub fun getStaked(): {Address: UInt64} {
        return self.staked
    }

    pub fun getStakedOf(address: Address): UInt64? {
        return self.staked[address]
    }




}