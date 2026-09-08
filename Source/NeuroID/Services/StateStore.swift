//
//  StateStore.swift
//  NeuroID
//

class StateStore {

    private(set) var configurationStatus: ConfigurationStatus = .notConfigured

    func setConfigurationStatus(_ status: ConfigurationStatus) {
        self.configurationStatus = status
    }

    private(set) var collectionStatus: CollectionStatus = .stopped

    func setCollectionStatus(_ status: CollectionStatus) {
        self.collectionStatus = status
    }

    private(set) var identityId: String?  // Formerly known as userID, now within the mobile sdk ONLY identityId

    func setIdentityId(_ identityId: String?) {
        self.identityId = identityId
    }
}
