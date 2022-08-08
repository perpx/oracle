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
func ownership_transfer_requested(to : felt):
end

@event
func ownership_transferred(frm : felt, to : felt):
end

#
# Storage
#

@storage_var
func owner() -> (owner : felt):
end

@storage_var
func pending_owner() -> (owner : felt):
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

# @notice Accept the transfer of ownership of the contract
# @dev Only pending owner can call
func _accept_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> ():
    let (caller) = get_caller_address()
    let (pending) = pending_owner.read()
    with_attr error_message("only pending owner can accept ownership"):
        assert caller = pending
    end

    let (old_owner) = owner.read()
    owner.write(pending)

    ownership_transferred.emit(old_owner, pending)
    return ()
end

# @notice Begin transfer ownership of the contract
# @dev Only owner can call
# @param _to The pending owner of the contract
func _transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _to : felt
) -> ():
    with_attr error_message("new owner cannot be the zero address"):
        assert_not_zero(_to)
    end
    only_owner()

    pending_owner.write(_to)
    ownership_transfer_requested.emit(_to)
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
