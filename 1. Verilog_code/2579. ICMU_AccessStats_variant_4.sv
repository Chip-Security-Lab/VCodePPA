//SystemVerilog
module ICMU_AccessStats #(
    parameter DW = 64,
    parameter STAT_W = 8
)(
    input clk,
    input access_en,
    input [DW-1:0] ctx_addr,
    output reg [DW-1:0] hot_ctx
);
    reg [STAT_W-1:0] access_count [0:(1<<DW)-1];
    reg [DW-1:0] max_addr;
    reg [STAT_W-1:0] max_count;
    wire [STAT_W-1:0] next_count;
    wire [STAT_W-1:0] count_diff;
    wire count_gt_max;

    // Conditional sum subtraction implementation
    assign count_diff = next_count - max_count;
    assign count_gt_max = ~count_diff[STAT_W-1];  // MSB indicates sign
    
    assign next_count = access_count[ctx_addr] + 1;

    always @(posedge clk) begin
        if (access_en) begin
            access_count[ctx_addr] <= next_count;
            
            if (count_gt_max) begin
                max_count <= next_count;
                max_addr <= ctx_addr;
            end
        end
        hot_ctx <= max_addr;
    end
endmodule