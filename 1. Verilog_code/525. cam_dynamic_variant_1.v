module cam_dynamic #(parameter MAX_WIDTH=64, DEPTH=128)(
    input clk,
    input [MAX_WIDTH-1:0] data_in,
    input [5:0] config_width,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    output [DEPTH-1:0] match_out
);

    reg [MAX_WIDTH-1:0] cam_entries [0:DEPTH-1];
    wire [MAX_WIDTH-1:0] masked_data;
    reg [MAX_WIDTH-1:0] masked_data_reg;
    wire [MAX_WIDTH-1:0] masked_entries [0:DEPTH-1];
    
    // Pre-compute masked input data
    assign masked_data = data_in & ((1 << config_width) - 1);
    
    // Register buffering for high fanout masked_data
    always @(posedge clk) begin
        masked_data_reg <= masked_data;
    end
    
    // Pre-compute masked entries
    genvar i;
    generate
        for(i=0; i<DEPTH; i=i+1) begin: mask_loop
            assign masked_entries[i] = cam_entries[i] & ((1 << config_width) - 1);
        end
    endgenerate
    
    // Write logic
    always @(posedge clk) begin
        if(write_en)
            cam_entries[write_addr] <= masked_data;
    end
    
    // Optimized comparison logic with buffered masked_data
    genvar j;
    generate
        for(j=0; j<DEPTH; j=j+1) begin: match_loop
            assign match_out[j] = (masked_data_reg == masked_entries[j]);
        end
    endgenerate

endmodule