//SystemVerilog
module parity_gen #(parameter WIDTH=8, parameter POS="LSB") (
    input [WIDTH-1:0] data_in,
    output reg [WIDTH:0] data_out
);

    // Use multi-level Dadda tree structure for parity calculation
    wire [3:0] level1_parity;
    wire [1:0] level2_parity;
    wire parity_bit;
    
    // Level 1: Group bits into 4 groups and calculate partial parities
    assign level1_parity[0] = ^data_in[1:0];
    assign level1_parity[1] = ^data_in[3:2];
    assign level1_parity[2] = ^data_in[5:4];
    assign level1_parity[3] = ^data_in[7:6];
    
    // Level 2: Combine level 1 results
    assign level2_parity[0] = level1_parity[0] ^ level1_parity[1];
    assign level2_parity[1] = level1_parity[2] ^ level1_parity[3];
    
    // Final parity
    assign parity_bit = level2_parity[0] ^ level2_parity[1];
    
    // Position the parity bit according to parameter
    always @(*) begin
        data_out = (POS == "MSB") ? {parity_bit, data_in} : {data_in, parity_bit};
    end
    
endmodule