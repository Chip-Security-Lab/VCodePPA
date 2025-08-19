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
    
    assign mask = (1 << config_width) - 1;
    
    always @(posedge clk) begin
        if(write_en)
            cam_entries[write_addr] <= data_in & mask;
    end
    
    genvar j;
    generate
        for(j=0; j<DEPTH; j=j+1) begin: match_loop
            assign match_out[j] = ((data_in & mask) == (cam_entries[j] & mask));
        end
    endgenerate
endmodule