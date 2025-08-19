//SystemVerilog
module true_dual_port_ram #(
    parameter DW = 16,  // 数据宽度
    parameter AW = 8    // 地址宽度
) (
    input                  clk_a, clk_b,
    input      [AW-1:0]    addr_a, addr_b,
    input                  wr_a, wr_b,
    input      [DW-1:0]    din_a, din_b,
    output reg [DW-1:0]    dout_a, dout_b
);

    // 存储器声明
    reg [DW-1:0] mem [(1<<AW)-1:0];
    
    // 端口A逻辑 - 合并写入和读取操作到同一个always块
    always @(posedge clk_a) begin
        if (wr_a) begin
            mem[addr_a] <= din_a;
            dout_a <= din_a; // 写入后直接更新输出
        end else begin
            dout_a <= mem[addr_a]; // 只读取
        end
    end
    
    // 端口B逻辑 - 合并写入和读取操作到同一个always块
    always @(posedge clk_b) begin
        if (wr_b) begin
            mem[addr_b] <= din_b;
            dout_b <= din_b; // 写入后直接更新输出
        end else begin
            dout_b <= mem[addr_b]; // 只读取
        end
    end

endmodule