//SystemVerilog
module parity_gen #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    output [WIDTH:0] data_out
);
    // Internal signals
    wire parity_bit;
    
    // Instantiate the parity calculator submodule
    parity_calculator #(
        .WIDTH(WIDTH)
    ) parity_calc_inst (
        .data(data_in),
        .parity(parity_bit)
    );
    
    // Instantiate the data formatter submodule
    data_formatter #(
        .WIDTH(WIDTH),
        .POS(POS)
    ) formatter_inst (
        .data_in(data_in),
        .parity_bit(parity_bit),
        .data_out(data_out)
    );
    
endmodule

module parity_calculator #(parameter WIDTH=8) (
    input [WIDTH-1:0] data,
    output reg parity
);
    // Calculate parity using while loop instead of reduction operator
    integer i;
    reg xor_result;
    
    always @(*) begin
        // Initialization before the loop
        i = 0;
        xor_result = 1'b0;
        
        // While loop implementation
        while (i < WIDTH) begin
            xor_result = xor_result ^ data[i];
            // Iteration step at the end of loop body
            i = i + 1;
        end
        
        // Assign final result
        parity = xor_result;
    end
    
endmodule

module data_formatter #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    input parity_bit,
    output reg [WIDTH:0] data_out
);
    // Format output data based on position parameter
    always @(*) begin
        // Using if-else instead of case for potentially better synthesis
        if (POS == "MSB") 
            data_out = {parity_bit, data_in};
        else 
            data_out = {data_in, parity_bit}; // LSB position
    end
    
endmodule