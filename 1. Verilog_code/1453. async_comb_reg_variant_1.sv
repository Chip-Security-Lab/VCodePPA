//SystemVerilog
// Top-level module
module async_comb_reg(
    input [7:0] parallel_data,
    input load_signal,
    output [7:0] reg_output
);
    // Direct connection from input to output through load_signal control
    reg [7:0] stored_value;
    
    // Combined storage and output logic
    always @(load_signal or parallel_data)
        if (load_signal) stored_value = parallel_data;
    
    // Direct assignment to output
    assign reg_output = stored_value;
    
endmodule