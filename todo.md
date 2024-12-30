- output to file instead of stdout
    - define fname spec for mulitple files 
    - Should work in distributed envornments (mpirun / torchrun)
        - spec should have some specifier to dfine different ranks 
        - runner should be able to splice together resutlts from different ranks
    - define ENV var to pick up filename

- refactor proflib.coll_events to AutoHashMap(coll_spec, []coll_res)
    - would need some way to limit mem usage and flush buffers if a limit is hit

- More performance metrics
    - mean/median/99th latency per ms
    - busbw

- some sample perf resutls
    - Llama-3.1 8B / 70B / 405B 
    - vllm vs other libs?
    - Training?
    - Num GPUs?

