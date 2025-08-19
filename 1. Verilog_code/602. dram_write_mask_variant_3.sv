//SystemVerilog
module dram_write_mask #(
    parameter DATA_WIDTH = 64,
    parameter MASK_WIDTH = 8
)(
    input clk,
    input [MASK_WIDTH-1:0] mask,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Pipeline registers
    reg [MASK_WIDTH-1:0] mask_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [DATA_WIDTH-1:0] masked_data;
    
    // First pipeline stage - register inputs
    always @(posedge clk) begin
        mask_reg <= mask;
        data_in_reg <= data_in;
    end
    
    // Second pipeline stage - mask logic with carry-save adder
    genvar i;
    generate
        for(i=0; i<MASK_WIDTH; i=i+1) begin : mask_logic
            wire [7:0] masked_byte;
            wire [7:0] carry_in;
            wire [7:0] carry_out;
            
            // Mask selection
            assign masked_byte = mask_reg[i] ? data_in_reg[(i*8) +: 8] : 8'b0;
            
            // Carry-save adder implementation
            assign carry_in = (i == 0) ? 8'b0 : carry_out;
            
            // Bit-wise carry-save addition
            assign carry_out[0] = masked_byte[0] & carry_in[0];
            assign masked_data[(i*8)] = masked_byte[0] ^ carry_in[0];
            
            genvar j;
            for(j=1; j<8; j=j+1) begin : carry_chain
                assign carry_out[j] = (masked_byte[j] & carry_in[j]) | 
                                    (masked_byte[j] & carry_out[j-1]) | 
                                    (carry_in[j] & carry_out[j-1]);
                assign masked_data[(i*8)+j] = masked_byte[j] ^ carry_in[j] ^ carry_out[j-1];
            end
        end
    endgenerate
    
    // Third pipeline stage - output register
    always @(posedge clk) begin
        data_out <= masked_data;
    end

endmodule