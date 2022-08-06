%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

# @title Oracle
# @notice Fast oracle contract used to get crypto price updates

#
# Structure
#

struct Info:
    member value : felt
    member timestamp : felt
end

#
# Events
#

@event
func OwnerUpdate(owner : felt):
end

@event
func MeasurementUpdate(key : felt, measurement : Info):
end

#
# Storage
#

@storage_var
func oracle_measurement(key : felt) -> (measurement : Info):
end

@storage_var
func oracle_owner() -> (owner : felt):
end

#
# Functions
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(address : felt):
    oracle_owner.write(address)
    return ()
end

# @notice Get the contract owner
# @return owner The contract owner
@view
func view_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    owner : felt
):
    let (owner) = oracle_owner.read()
    return (owner)
end

# @notice Update the contract owner
# @dev Only contract owner can update
@external
func update_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_owner : felt
) -> ():
    with_attr error_message("new owner cannot be the zero address"):
        assert_not_zero(new_owner)
    end

    let (caller) = get_caller_address()
    let (owner) = oracle_owner.read()
    with_attr error_message("only current owner can update"):
        assert caller = owner
    end

    oracle_owner.write(new_owner)

    OwnerUpdate.emit(new_owner)
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
# @param key The key of the measurement
# @param measurement The measurement
@external
func set_measurement{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    key : felt, measurement : Info
) -> ():
    let (caller) = get_caller_address()
    let (owner) = oracle_owner.read()
    with_attr error_message("only current owner can update"):
        assert caller = owner
    end

    oracle_measurement.write(key, measurement)

    MeasurementUpdate.emit(key, measurement)
    return ()
end
