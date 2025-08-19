//SystemVerilog
module bin2thermometer #(parameter BIN_WIDTH = 3) (
    input      [BIN_WIDTH-1:0] bin_input,
    output reg [(2**BIN_WIDTH)-2:0] therm_output
);

    // Carry chain signals
    wire [2**BIN_WIDTH-2:0] carry_chain;
    wire [2**BIN_WIDTH-2:0] sum_chain;
    
    // Generate carry chain
    assign carry_chain[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < 2**BIN_WIDTH-2; i = i + 1) begin : gen_carry
            assign carry_chain[i+1] = (bin_input > i) ? 1'b1 : carry_chain[i];
        end
    endgenerate
    
    // Generate sum chain
    generate
        for (i = 0; i < 2**BIN_WIDTH-1; i = i + 1) begin : gen_sum
            assign sum_chain[i] = carry_chain[i] ^ (bin_input > i);
        end
    endgenerate
    
    // Output assignment
    always @(*) begin
        therm_output = sum_chain;
    end

endmodule