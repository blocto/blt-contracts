import "NonFungibleToken"
import "ViewResolver"
import "MetadataViews"

access(all)
contract BloctoPassStamp: NonFungibleToken {

    // An entitlement for NFTMinter access
    access(all) entitlement NFTMinterEntitlement

    access(all)
    var totalSupply: UInt64
    
    access(all)
    let CollectionStoragePath: StoragePath
    
    access(all)
    let CollectionPublicPath: PublicPath
    
    access(all)
    let MinterStoragePath: StoragePath
    
    access(all)
    event ContractInitialized()
    
    access(all)
    event Withdraw(id: UInt64, from: Address?)
    
    access(all)
    event Deposit(id: UInt64, to: Address?)
    
    access(all)
    resource interface BloctoPassPublic{ 
        access(all)
        fun getMessage(): String
    }
    
    access(all)
    resource NFT: NonFungibleToken.NFT, BloctoPassPublic{ 
        
        // BloctoPassStamp ID
        access(all)
        let id: UInt64
        
        // BloctoPassStamp message
        access(self)
        var message: String
        
        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
            return <-create Collection()
        }
        
        init(initID: UInt64, message: String){ 
            self.id = initID
            self.message = message
        }
        
        access(all)
        fun getMessage(): String{ 
            return self.message
        }

        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "Blocto Pass Stamp",
                        description: "Blocto Pass Stamp",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://blocto.io/"
                        )
                    )
            }
            return nil
        }
    }
    
    access(all)
    resource Collection: NonFungibleToken.Collection { 
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all)
        var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        // withdraw removes an NFT from the collection and moves it to the caller
        // withdrawal is disabled during lockup period
        access(NonFungibleToken.Withdraw)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        access(all)
        fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
            let token <- token as! @BloctoPassStamp.NFT
            let id: UInt64 = token.id
            
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        // getIDs returns an array of the IDs that are in the collection
        access(all)
        view fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }
        
        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        access(all)
        view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
            return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
        }
        
        access(all)
        view fun getSupportedNFTTypes():{ Type: Bool}{ 
            panic("implement me")
        }
        
        access(all)
        view fun isSupportedNFTType(type: Type): Bool{ 
            panic("implement me")
        }
        
        access(all)
        fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
            return <-create Collection()
        }
    }
    
    // public function that anyone can call to create a new empty collection
    access(all)
    fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
        return <-create Collection()
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.EVMBridgedMetadata>()
        ]
    }


    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                let collectionData = MetadataViews.NFTCollectionData(
                    storagePath: self.CollectionStoragePath,
                    publicPath: self.CollectionPublicPath,
                    publicCollection: Type<&BloctoPassStamp.Collection>(),
                    publicLinkedType: Type<&BloctoPassStamp.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <-BloctoPassStamp.createEmptyCollection(nftType: Type<@BloctoPassStamp.NFT>())
                    })
                )
                return collectionData
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: ""
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Blcoto Pass Stamp",
                    description: "",
                    externalURL: MetadataViews.ExternalURL("https://blocto.io/"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {
                        "twitter": MetadataViews.ExternalURL("https://x.com/BloctoApp")
                    }
                )
            case Type<MetadataViews.EVMBridgedMetadata>():
                // Implementing this view gives the project control over how the bridged NFT is represented as an ERC721
                // when bridged to EVM on Flow via the public infrastructure bridge.

                // Compose the contract-level URI. In this case, the contract metadata is located on some HTTP host,
                // but it could be IPFS, S3, a data URL containing the JSON directly, etc.
                return MetadataViews.EVMBridgedMetadata(
                    name: "BloctoPassStamp",
                    symbol: "BLTPS",
                    uri: MetadataViews.URI(
                        baseURI: nil, // setting baseURI as nil sets the given value as the uri field value
                        value: ""
                    )
                )
        }
        return nil
    }
    
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    access(all)
    resource NFTMinter{ 
        
        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        access(NFTMinterEntitlement)
        fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, message: String){ 
            
            // create a new NFT
            var newNFT <- create NFT(initID: BloctoPassStamp.totalSupply, message: message)
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
            BloctoPassStamp.totalSupply = BloctoPassStamp.totalSupply + 1
        }
    }
    
    init(){ 
        // Initialize the total supply
        self.totalSupply = 0
        self.CollectionStoragePath = /storage/bloctoPassStampCollection
        self.CollectionPublicPath = /public/bloctoPassStampCollection
        self.MinterStoragePath = /storage/bloctoPassStampMinter
        
        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.storage.save(<-collection, to: self.CollectionStoragePath)
        
        // create a public capability for the collection
        var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(self.CollectionStoragePath)
        self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
        
        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.storage.save(<-minter, to: self.MinterStoragePath)
        emit ContractInitialized()
    }
}