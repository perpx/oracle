%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from contracts.utils import (
    only_owner,
    init_owner,
    _transfer_ownership,
    _accept_ownership,
    get_owner,
)

# @title Oracle
# @notice Fast oracle contract used to get crypto price updates

#
# Structure
#

struct Info:
    member value : felt
    member decimals : felt
    member timestamp : felt
end

#
# Events
#

@event
func ownership_transfer_requested(to : felt):
end

@event
func measurement_update(key : felt, measurement : Info):
end

#
# Storage
#

@storage_var
func oracle_measurement(key : felt) -> (measurement : Info):
end

#
# Functions
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    init_owner(owner)
    return ()
end

# @notice View the contract owner
# @return owner The contract owner
@view
func view_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    owner : felt
):
    let (owner) = get_owner()
    return (owner)
end

# @notice Allows contract owner to begin transfer of contract ownership
# @dev Only callable by contract owner
# @param new_owner The proposed new contract owner
@external
func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_owner : felt
) -> ():
    _transfer_ownership(new_owner)
    return ()
end

# @notice Allows the contract ownership recipient to accept the transfer
# @dev Only callable by pending contract owner
@external
func accept_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    _accept_ownership()
    return ()
end

# @notice Get measurement
# @param key The felt representation for the measurement "base/quote"
# @return measurement The measurement
@view
func get_measurement{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    key : felt
) -> (measurement : Info):
    let (measurement) = oracle_measurement.read(key)
    return (measurement)
end

# @notice Update measurement
# @dev Only callable by contract owner
# @param key The key of the measurement
# @param measurement The measurement
@external
func set_measurement{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    key : felt, measurement : Info
) -> ():
    only_owner()

    oracle_measurement.write(key, measurement)

    measurement_update.emit(key, measurement)
    return ()
end
