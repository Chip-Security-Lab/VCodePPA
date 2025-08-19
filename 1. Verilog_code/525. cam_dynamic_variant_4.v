module cam_dynamic #(parameter MAX_WIDTH=64, DEPTH=128)(
    input clk,
    input [MAX_WIDTH-1:0] data_in,
    input [5:0] config_width,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    output [DEPTH-1:0] match_out
);
    reg [MAX_WIDTH-1:0] cam_entries [0:DEPTH-1];
    wire [MAX_WIDTH-1:0] mask;
    wire [MAX_WIDTH-1:0] masked_data_in;
    wire [MAX_WIDTH-1:0] masked_cam_entries [0:DEPTH-1];
    wire [DEPTH-1:0] match_out_pre;
    
    // Generate mask using shift and subtract
    assign mask = (1 << config_width) - 1;
    
    // Apply mask to inputs
    assign masked_data_in = data_in & mask;
    
    // Write logic
    always @(posedge clk) begin
        if(write_en)
            cam_entries[write_addr] <= data_in & mask;
    end
    
    // Optimized comparison using parallel prefix tree
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin: comp_loop
            wire [5:0] xor_result;
            wire [5:0] prefix_and;
            
            // Parallel XOR for difference
            assign xor_result = masked_data_in[5:0] ^ masked_cam_entries[i][5:0];
            
            // Parallel prefix AND tree
            assign prefix_and[0] = ~xor_result[0];
            assign prefix_and[1] = ~xor_result[1] & prefix_and[0];
            assign prefix_and[2] = ~xor_result[2] & prefix_and[1];
            assign prefix_and[3] = ~xor_result[3] & prefix_and[2];
            assign prefix_and[4] = ~xor_result[4] & prefix_and[3];
            assign prefix_and[5] = ~xor_result[5] & prefix_and[4];
            
            // Final match output
            assign match_out_pre[i] = prefix_and[5];
        end
    endgenerate
    
    // Register output for better timing
    reg [DEPTH-1:0] match_out_reg;
    always @(posedge clk) begin
        match_out_reg <= match_out_pre;
    end
    
    assign match_out = match_out_reg;
endmodule