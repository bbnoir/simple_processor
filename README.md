# simple_processor
This project is the final project for the course `Computer Organization` at National Yang Ming Chiao Tung University, Taiwan.
The project is to implement a simple processor with a simple ISA based on MIPS. The processor is implemented in Verilog.
For more information, please refer to the [specification](./CO_2023_FinalProject.pdf).

## Test
To test using [icarus verilog](https://bleyer.org/icarus/), run the following command:
```bash
iverilog -o test testbench.v
```
for pipeline version:
```bash
iverilog -o test testbench_pipeline.v
```
Then, run the testbench:
```bash
vvp test
```
There will be a Totoro if the test is passed.
```
        ----------------------------
        --                        --       |__||
        --  Congratulations !!    --      / O.O  |
        --                        --    /_____   |
        --  Simulation PASS!!     --   /^ ^ ^ \  |
        --                        --  |^ ^ ^ ^ |w|
        ----------------------------   \m___m__|_|
```

## More Information
- For the pipeline version, I only construct the pipeline for 3 stages because the specification only requires RTL level testing. This is not a complete implemantation of 5 stages pipeline written in the textbook `Computer Organization and Design` by David A. Patterson and John L. Hennessy. 
- I have tried to keep the code minimal and easy to understand though I am more familiar with system verilog. Please feel free to submit an issue if you have any question or suggestion.
