A Complete Example
==================

The following is a use case that uses most of the features presented in previous sections:

## A Contract Implementing a Linked List

```solidity
contract LinkedList {
  struct Element {
    bytes32 nextKey;
    uint256 exists;
  }

  struct List {
    bytes32 head;
    mapping(bytes32 => Element) elements;
  }

  List list;

  /**
   * @notice Inserts an element into a doubly linked list.
   * @param  key The key of the element to insert.
   * @param  afterKey The key of the element that comes before the
   *         element to insert. Or 0 to insert at the head.
   */
  function insertAfter(bytes32 key, bytes32 afterKey) public {
    require(key != bytes32(0), "Key must be defined");
    require(!contains(key), "Can't insert an existing element");
    require(afterKey != key, "Key cannot be the same as afterKey");

    Element storage element = list.elements[key];
    element.exists = 1;
    if (afterKey == 0) {
      element.nextKey = list.head; // ghost(2-vocab): updateSucc(key, list.head)
      list.head = key;
    } else {
      require(contains(afterKey),
          "If afterKey is defined, it must exist in the list");
      bytes32 tmp = list.elements[afterKey].nextKey;
      element.nextKey = tmp;
      list.elements[afterKey].nextKey = key;
    }
  }

  function getSucc(bytes32 key) public returns (bytes32) {
    return list.elements[key].nextKey;
  }

  function head() public returns (bytes32) {
    return list.head;
  }
  /**
   * @notice Returns whether or not a particular key is present in
   *         the sorted list.
   * @param  key The element key.
   * @return Whether or not the key is in the sorted list.
   */
  function contains(bytes32 key) public view returns (bool) {
    return list.elements[key].exists != 0;
  }
}
```

## A Spec Using a Ghost to Compute Reachability

```cvl
methods {
  insertAfter(bytes32, bytes32) envfree
  getSucc(bytes32) returns (bytes32) envfree
  contains(bytes32) returns (bool) envfree
  head() returns (bytes32) envfree
}

sort Node;

ghost toNode(bytes32) returns Node;
ghost reach(Node, Node) returns bool {
  axiom forall Node X. reach(X, X);
  axiom forall Node X. forall Node Y.
      reach(X, Y) && reach(Y, X) => X == Y;
  axiom forall Node X. forall Node Y. forall Node Z.
      reach(X, Y) && reach(Y, Z) => reach(X, Z);
  axiom forall Node X. forall Node Y. forall Node Z.
      reach(X, Y) && reach(X, Z) => (reach(Y, Z) || reach(Z,Y));
}

definition isSucc(Node a, Node b) returns bool =
    reach(a, b) && a != b &&
        (forall Node X. reach(a, X) && reach(X, b) => (a == X || b == X));

definition updateSucc(Node a, Node b) returns bool =
    forall Node X. forall Node Y. reach@new(X, Y) ==
        (X == Y ||
        (reach@old(X, Y) && !(reach@old(X, a) && a != Y &&
            reach@old(a, Y))) ||
        (reach@old(X, a) && reach@old(b, Y)));

hook Sstore (slot 0).(offset 32)[KEY bytes32 key].(offset 0)
    bytes32 newNextKey {
  havoc reach assuming updateSucc(toNode(key), toNode(newNextKey));
}

hook Sload bytes32 nextKey (slot 0).(offset 32)[KEY bytes32 key].(offset 0) {
  require isSucc(toNode(key), toNode(nextKey));
}

rule checkGetSucc {
  bytes32 key;
  bytes32 afterKey = getSucc(key);
  assert reach(toNode(key), toNode(afterKey));
}

// Rules for full correctness of API calls.
rule checkInsertHead {
  bytes32 key;
  bytes32 afterKey;
  bytes32 headKey = sinvoke head();
  require !reach(toNode(key), toNode(afterKey));
  // inserts at head
  require afterKey == 0;
  insertAfter@norevert(key, afterKey);
  assert reach(toNode(key), toNode(headKey));
}

rule checkInsertSuccessor {
  bytes32 key;
  bytes32 afterKey;
  require !reach(toNode(afterKey), toNode(key));
  // do not insert at head
  require afterKey != 0;
  insertAfter@norevert(key, afterKey);
  assert reach(toNode(afterKey), toNode(key));
}

rule checkInsert {
  bytes32 key;
  bytes32 afterKey;
  bytes32 randoBoi;
  bytes32 oldHeadKey = head@norevert();
  require reach(toNode(oldHeadKey), toNode(randoBoi));
  // this could be replaced by a hook, but we need to be able to
  // put invokes in hooks for that to work
  require contains(key) <=> reach(toNode(oldHeadKey), toNode(key));
  require contains(afterKey) <=> reach(toNode(oldHeadKey), toNode(afterKey));
  insertAfter@norevert(key, afterKey);    bytes32 newHeadKey = head@norevert();
  assert reach(toNode(newHeadKey), toNode(randoBoi));
}
```
