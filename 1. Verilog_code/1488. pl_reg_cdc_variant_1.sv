//SystemVerilog
module pl_reg_cdc #(
    parameter W = 8
) (
    input wire src_clk,
    input wire dst_clk,
    input wire [W-1:0] src_data,
    output reg [W-1:0] dst_data
);

    // 使用2级同步器来提高稳定性，防止亚稳态
    reg [W-1:0] sync_reg1;
    reg [W-1:0] sync_reg2;
    
    // 源时钟域
    always @(posedge src_clk) begin
        sync_reg1 <= src_data;
    end
    
    // 目标时钟域
    reg [W-1:0] inverted_data;
    reg [W-1:0] subtraction_result;
    reg subtract_mode;
    
    always @(posedge dst_clk) begin
        sync_reg2 <= sync_reg1;
        
        // 条件反相减法器实现
        subtract_mode <= (sync_reg2[W-1] ^ sync_reg1[W-1]); // 判断是否需要减法
        inverted_data <= ~sync_reg1;
        
        if (subtract_mode) begin
            // 条件反相减法: sync_reg2 - sync_reg1 = sync_reg2 + (~sync_reg1 + 1)
            subtraction_result <= sync_reg2 + inverted_data + 1'b1;
            dst_data <= subtraction_result;
        end else begin
            // 直接传递
            dst_data <= sync_reg2;
        end
    end

endmodule