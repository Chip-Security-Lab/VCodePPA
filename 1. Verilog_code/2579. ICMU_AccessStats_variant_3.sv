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
    reg [STAT_W-1:0] access_count_buf;
    reg [DW-1:0] ctx_addr_buf;
    reg access_en_buf;

    always @(posedge clk) begin
        access_en_buf <= access_en;
        ctx_addr_buf <= ctx_addr;
        access_count_buf <= access_count[ctx_addr_buf];
    end

    always @(posedge clk) begin
        if (access_en_buf) begin
            access_count[ctx_addr_buf] <= access_count_buf + 1;
            
            if (access_count_buf >= max_count) begin
                max_count <= access_count_buf;
                max_addr <= ctx_addr_buf;
            end
        end
        hot_ctx <= max_addr;
    end
endmodule