//SystemVerilog
module decoder_partial_match #(
    parameter MASK = 4'hF
)(
    input wire [3:0] addr_in,
    input wire clk,
    input wire rst_n,
    output reg [7:0] device_sel
);
    // 流水线寄存器
    reg [3:0] masked_addr;
    
    // 优化比较操作的流水线级
    reg addr_match;
    
    // 优化的流水线数据流
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有流水线寄存器
            masked_addr <= 4'h0;
            addr_match <= 1'b0;
            device_sel <= 8'h00;
        end else begin
            // 第一级：应用掩码
            masked_addr <= addr_in & MASK;
            
            // 第二级：优化比较逻辑
            // 直接比较与目标值 4'hA (1010)的匹配情况
            // 使用显式的位比较，对于特定值可以更高效
            addr_match <= (masked_addr[3:0] == 4'b1010);
            
            // 第三级：优化输出生成逻辑
            // 使用移位操作替代条件赋值，可能在某些工具链中有更好的实现
            device_sel <= {7'b0000000, addr_match};
        end
    end
endmodule