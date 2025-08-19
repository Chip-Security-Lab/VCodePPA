//SystemVerilog
module sync_pos_edge_reg(
    input clk, rst_n,
    input [7:0] data_in,
    input load_en,
    output reg [7:0] data_out
);
    // 删除中间控制变量，直接在时序逻辑中处理条件
    // 避免组合逻辑路径中的额外延迟
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位路径独立处理，减少关键路径延迟
            data_out <= 8'b0;
        end else begin
            // 数据加载逻辑简化，减少逻辑层级
            data_out <= load_en ? data_in : data_out;
        end
    end
endmodule