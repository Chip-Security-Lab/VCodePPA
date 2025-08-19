//SystemVerilog
module Demux_LUT #(parameter DW=8, AW=3, LUT_SIZE=8) (
    input [DW-1:0] data_in,
    input [AW-1:0] addr,
    input [LUT_SIZE-1:0][AW-1:0] remap_table,
    output [LUT_SIZE-1:0][DW-1:0] data_out
);
    wire [AW-1:0] actual_addr = remap_table[addr];
    
    // LUT-based subtractor tables for 8-bit operation
    reg [7:0] diff_lut [0:1][0:1][0:1];  // [a][b][borrow_in] -> difference bit
    reg [7:0] borrow_lut [0:1][0:1][0:1];  // [a][b][borrow_in] -> borrow_out
    
    // Initialize LUT tables
    initial begin
        // diff_lut[a][b][borrow_in] = a ^ b ^ borrow_in
        diff_lut[0][0][0] = 0;
        diff_lut[0][0][1] = 1;
        diff_lut[0][1][0] = 1;
        diff_lut[0][1][1] = 0;
        diff_lut[1][0][0] = 1;
        diff_lut[1][0][1] = 0;
        diff_lut[1][1][0] = 0;
        diff_lut[1][1][1] = 1;
        
        // borrow_lut[a][b][borrow_in] = (~a & b) | (borrow_in & (~(a ^ b)))
        borrow_lut[0][0][0] = 0;
        borrow_lut[0][0][1] = 1;
        borrow_lut[0][1][0] = 1;
        borrow_lut[0][1][1] = 1;
        borrow_lut[1][0][0] = 0;
        borrow_lut[1][0][1] = 0;
        borrow_lut[1][1][0] = 0;
        borrow_lut[1][1][1] = 1;
    end
    
    // Initialize all outputs to zero
    genvar i;
    generate
        for (i = 0; i < LUT_SIZE; i = i + 1) begin : gen_outputs
            wire match;
            wire [AW:0] borrow;
            wire [AW-1:0] diff;
            
            // Initial borrow bit
            assign borrow[0] = 1'b0;
            
            genvar j;
            for (j = 0; j < AW; j = j + 1) begin : gen_lut_sub
                wire a_bit = actual_addr[j];
                wire b_bit = i[j];
                
                // Use lookup tables for subtraction
                assign diff[j] = diff_lut[a_bit][b_bit][borrow[j]];
                assign borrow[j+1] = borrow_lut[a_bit][b_bit][borrow[j]];
            end
            
            // Check if actual_addr equals i
            assign match = (borrow[AW] == 1'b0) && 
                          (&(~diff)) &&  // All diff bits must be 0
                          (actual_addr < LUT_SIZE);
                          
            assign data_out[i] = match ? data_in : {DW{1'b0}};
        end
    endgenerate
endmodule