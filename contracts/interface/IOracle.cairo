%lang starknet

from contracts.oracle import Info

# @title Oracle interface
# @notice The interface for an oracle on starknet

@contract_interface
namespace IOracle:
    # Functions
    #

    # @notice View the contract owner
    # @return owner The contract owner
    func view_owner() -> (owner : felt):
    end

    # @notice Allows contract owner to begin transfer of contract ownership
    # @dev Only callable by contract owner
    # @param new_owner The proposed new contract owner
    func transfer_ownership(new_owner : felt) -> ():
    end

    # @notice Allows the contract ownership recipient to accept the transfer
    # @dev Only callable by pending contract owner
    func accept_ownership() -> ():
    end

    # @notice Get measurement
    # @param key The felt representation for the measurement "base/quote"
    # @return measurement The measurement
    func get_measurement(key : felt) -> (measurement : Info):
    end

    # @notice Update measurement
    # @dev Only callable by contract owner
    # @param key The key of the measurement
    # @param measurement The measurement
    func set_measurement(key : felt, measurement : Info) -> ():
    end
end
