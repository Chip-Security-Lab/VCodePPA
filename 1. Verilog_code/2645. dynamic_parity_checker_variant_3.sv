//SystemVerilog
module dynamic_parity_checker #(
    parameter MAX_WIDTH = 64
)(
    input [$clog2(MAX_WIDTH)-1:0] width,
    input [MAX_WIDTH-1:0] data,
    output parity
);
    // Level 1: Initial parity bits (2-bit groups)
    wire [MAX_WIDTH/2-1:0] level1_parity;
    genvar i;
    generate
        for (i = 0; i < MAX_WIDTH/2; i = i+1) begin : gen_level1
            assign level1_parity[i] = (2*i < width) ? 
                ((2*i+1 < width) ? data[2*i] ^ data[2*i+1] : data[2*i]) : 1'b0;
        end
    endgenerate
    
    // Level 2: Combine level 1 results (4-bit groups)
    wire [MAX_WIDTH/4-1:0] level2_parity;
    generate
        for (i = 0; i < MAX_WIDTH/4; i = i+1) begin : gen_level2
            assign level2_parity[i] = level1_parity[2*i] ^ level1_parity[2*i+1];
        end
    endgenerate
    
    // Level 3: Combine level 2 results (8-bit groups)
    wire [MAX_WIDTH/8-1:0] level3_parity;
    generate
        for (i = 0; i < MAX_WIDTH/8; i = i+1) begin : gen_level3
            assign level3_parity[i] = level2_parity[2*i] ^ level2_parity[2*i+1];
        end
    endgenerate
    
    // Level 4: Combine level 3 results (16-bit groups)
    wire [MAX_WIDTH/16-1:0] level4_parity;
    generate
        for (i = 0; i < MAX_WIDTH/16; i = i+1) begin : gen_level4
            assign level4_parity[i] = level3_parity[2*i] ^ level3_parity[2*i+1];
        end
    endgenerate
    
    // Level 5: Combine level 4 results (32-bit groups)
    wire [MAX_WIDTH/32-1:0] level5_parity;
    generate
        for (i = 0; i < MAX_WIDTH/32; i = i+1) begin : gen_level5
            assign level5_parity[i] = level4_parity[2*i] ^ level4_parity[2*i+1];
        end
    endgenerate
    
    // Final level: Combine level 5 results (64-bit)
    assign parity = level5_parity[0] ^ level5_parity[1];
    
endmodule