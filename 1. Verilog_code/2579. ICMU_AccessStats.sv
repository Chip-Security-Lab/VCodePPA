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

    always @(posedge clk) begin
        if (access_en) begin
            access_count[ctx_addr] <= access_count[ctx_addr] + 1;
            
            if (access_count[ctx_addr] >= max_count) begin
                max_count <= access_count[ctx_addr];
                max_addr <= ctx_addr;
            end
        end
        hot_ctx <= max_addr;
    end
endmodule
