//SystemVerilog
module neg_edge_sync_reset_reg(
    input clk, rst,
    input [15:0] d_in,
    input load,
    output reg [15:0] q_out
);
    always @(negedge clk) begin
        if (rst) begin
            q_out <= 16'b0;  // 复位条件：rst=1时清零
        end else if (load) begin
            q_out <= d_in;   // 加载条件：rst=0且load=1时加载新数据
        end else begin
            q_out <= q_out;  // 保持条件：rst=0且load=0时保持当前值
        end
    end
endmodule