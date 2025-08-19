//SystemVerilog
module decoder_hybrid_rst #(parameter SYNC_RST=1) (
    input clk, async_rst, sync_rst,
    input [3:0] addr,
    output reg [15:0] decoded
);
    reg [15:0] decoded_comb;
    reg reset_reg;
    
    // 组合逻辑处理解码
    always @(*) begin
        decoded_comb = 1'b1 << addr;
    end
    
    // 复位逻辑处理
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            reset_reg <= 1'b1;
            decoded <= 16'b0;
        end
        else begin
            reset_reg <= (SYNC_RST && sync_rst) ? 1'b1 : 1'b0;
            if (reset_reg) begin
                decoded <= 16'b0;
            end
            else begin
                decoded <= decoded_comb;
            end
        end
    end
endmodule