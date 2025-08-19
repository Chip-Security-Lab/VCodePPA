module async_comb_reg(
    input [7:0] parallel_data,
    input load_signal,
    output [7:0] reg_output
);
    reg [7:0] stored_value;
    
    always @(load_signal or parallel_data)
        if (load_signal) stored_value = parallel_data;
    
    assign reg_output = stored_value;
endmodule