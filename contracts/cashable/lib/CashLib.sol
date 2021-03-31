// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.3;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";


library CashLib is EnumerableSet {

    address public constant ETH = address(0);

    struct Cash {
        uint256 id;
        address holder;
        uint256 nominal;
    }

    struct CashSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(CashSet storage set, Cash value) internal returns(bool) {
        return _add(set._inner, abi.encode(value.id, value.holder, value.nominal));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(CashSet storage set, Cash value) internal returns(bool) {
        return _remove(set._inner, abi.encode(value.id, value.holder, value.nominal));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(CashSet storage set, Cash value) internal view returns(bool) {
        return _contains(set._inner, abi.encode(value.id, value.holder, value.nominal));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(CashSet storage set) internal view returns(uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the id of cash stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function atId(CashSet storage set, uint256 index) internal view returns(uint256 _id) {
        (_id,,) = abi.decode(
          _at(set._inner, index),
          uint255, address, uint256
        );
    }

    /**
     * @dev Returns the holder of cash stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function atHolder(CashSet storage set, uint256 index) internal view returns(address _holder) {
        (,_holder,) = abi.decode(
          _at(set._inner, index),
          uint255, address, uint256
        );
    }

    /**
     * @dev Returns the nominal of cash stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function atNominal(CashSet storage set, uint256 index) internal view returns(uint256 _nominal) {
        (,,_nominal) = abi.decode(
          _at(set._inner, index),
          uint255, address, uint256
        );
    }

}
