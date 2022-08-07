%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

#
# Events
#
@event
func owner_initialized(owner : felt):
end

@event
func ownership_transferred(owner : felt):
end

#
# Storage
#

@storage_var
func owner() -> (owner : felt):
end

#
# Modifiers
#

# @notice Modifier for only owner callables
func only_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    let (caller) = get_caller_address()
    let (_owner) = owner.read()

    with_attr error_message("only current owner can update"):
        assert caller = _owner
    end
    return ()
end

#
# Functions
#

# @notice Initialize the contract owner
# @param _owner The contract owner
func init_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _owner : felt
) -> ():
    with_attr error_message("owner cannot be the zero address"):
        assert_not_zero(_owner)
    end

    owner.write(_owner)
    owner_initialized.emit(_owner)
    return ()
end

# @notice Transfer ownership of the contract
func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_owner : felt
) -> ():
    with_attr error_message("new owner cannot be the zero address"):
        assert_not_zero(new_owner)
    end
    only_owner()

    owner.write(new_owner)
    ownership_transferred.emit(new_owner)
    return ()
end

# @notice Get the contact owner
# @return _owner The contract owner
func get_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    _owner : felt
):
    let (_owner) = owner.read()
    return (_owner)
end
