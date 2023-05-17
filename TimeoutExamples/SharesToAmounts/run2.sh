certoraRun main.sol:PoolExample underlying.sol \
--verify PoolExample:Spec.spec \
--link PoolExample:asset=underlying \
--solc solc8.10 \
--staging \
--send_only \
--rule depositRedeemMonotinicity \
--rule depositMonotonicity \
--rule redeemMonotonicity \
--msg "depositRedeemMonotinicity "