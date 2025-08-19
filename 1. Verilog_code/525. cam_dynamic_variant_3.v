module cam_dynamic #(parameter MAX_WIDTH=64, DEPTH=128)(
    input clk,
    input [MAX_WIDTH-1:0] data_in,
    input [5:0] config_width,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    output [DEPTH-1:0] match_out
);

    // Register declarations
    reg [MAX_WIDTH-1:0] cam_entries [0:DEPTH-1];
    reg [MAX_WIDTH-1:0] mask_reg;
    reg [MAX_WIDTH-1:0] masked_data_in_reg;
    
    // Wire declarations
    wire [MAX_WIDTH-1:0] mask;
    wire [MAX_WIDTH-1:0] masked_data_in;
    wire [MAX_WIDTH-1:0] masked_entries [0:DEPTH-1];
    
    // Combinational logic for mask generation
    assign mask = (1 << config_width) - 1;
    
    // Register mask and masked data for better timing
    always @(posedge clk) begin
        mask_reg <= mask;
        masked_data_in_reg <= data_in & mask;
    end
    
    // Generate masked entries with registered mask
    genvar j;
    generate
        for(j=0; j<DEPTH; j=j+1) begin: mask_loop
            assign masked_entries[j] = cam_entries[j] & mask_reg;
        end
    endgenerate
    
    // Generate match logic with registered masked data
    generate
        for(j=0; j<DEPTH; j=j+1) begin: match_loop
            assign match_out[j] = (masked_data_in_reg == masked_entries[j]);
        end
    endgenerate
    
    // Sequential logic for CAM entries
    always @(posedge clk) begin
        if(write_en) begin
            cam_entries[write_addr] <= masked_data_in_reg;
        end
    end

endmodule