(using-opcodes)=
Using Opcode Hooks
==================

{ref}`opcode-hooks` are useful for reasoning about the low-level behavior of
your contracts, and for accessing EVM state that is otherwise unavailable in
CVL.  This guide gives a few examples of how opcode hooks can be used.

```{contents}
```

Accessing environment variables
-------------------------------

In CVL, you can access EVM variables like `msg.sender` using an
{ref}`environment object <env>`.  However, `env` objects do not contain all of
the EVM state that is available to contracts.

We made this choice for a few reasons: for one, it would be annoying to have to
manually specify that global constants like the chain ID are same in every
transaction.  Another is that we have tried to decouple CVL from EVM as much as
possible.

Nevertheless, sometimes you need access to EVM variables that are not included
in the `env` type, such as the `CHAINID` or `GASPRICE`.  You can use opcode
hooks on the corresponding instructions to restrict these values or save them
in {ref}`ghost-variables` for use in rules.

% TODO: make an actual example in the examples repo

For example, if your contract uses `chainid()` to detect whether it is running
on the Ethereum Mainnet, you could ensure that the chain ID is always 1 (which
is the Ethereum Mainnet chain ID) by adding the following hook:
```cvl
hook CHAINID uint id {
    require id == 1;
}
```

Alternatively, you could save the chain ID in a ghost variable and then use it
in your rule:
```cvl
ghost uint chain_id;
hook CHAINID uint id {
    chain_id = id;
}

/// The contract's behavior changes appropriately when run on mainnet
rule chainid_behavior_correct {
    ...
    if (chain_id == 1) {
        ...
    } else {
        ...
    }
}
```

Detecting `CALL` instructions
-----------------------------

Suppose you want to ensure that a specific contract function never makes an
external call while it is in an emergency shutdown mode.  In order to verify
this property, you need to know whether the contract has made a call.

You can use a hook on the `CALL` opcode to write such a rule:
```cvl
ghost bool made_call;

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    made_call = true;
}

/// While in `emergencyMode`, no function can make an external call.
rule no_call_during_emergency {
    require !made_call;
    require emergencyMode();

    method f; env e; calldataarg args;
    f(e, args);

    assert !made_call;
}
```

In this example, the `made_call` variable gets set to `true` whenever the
contract executes the `CALL` opcode, which is used to make external calls.  The
rule simply asserts that this variable is `false` (note that we required
`!made_call` to avoid counterexamples where `made_call` started out set).

% TODO:
% Reasoning about new contracts
% -----------------------------
% Using the `CREATE1` and `CREATE2` opcode hooks
% 
% Detecting events
% ----------------
% Using the `LOGn` opcodes.
%
% ## Using call hooks
% 
% ```{todo}
% Ensure that the `ecrecover` function is checked whenever the signed transaction
% function changes a balance
% ```
% 
% ### Call hooks or summarization?
% 
% ```{todo}
% Now we have hooks on calls and also summaries that can call contract functions;
% these do similar things.  Which is the recommended way / what are the tradeoffs?
% ```
% 
