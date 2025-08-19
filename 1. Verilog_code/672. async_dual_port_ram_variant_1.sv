//SystemVerilog
module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b
);

    // 使用二维数组实现内存阵列，提高访问效率
    reg [DATA_WIDTH-1:0] ram [0:(2**ADDR_WIDTH)-1];
    
    // 合并地址和数据寄存器，减少寄存器数量
    reg [ADDR_WIDTH+DATA_WIDTH+1:0] port_a_reg, port_b_reg;
    
    // 地址和数据锁存，使用位拼接优化
    always @(posedge clk) begin
        port_a_reg <= {we_a, addr_a, din_a};
        port_b_reg <= {we_b, addr_b, din_b};
    end

    // 写操作流水线，使用位选择优化
    always @(posedge clk) begin
        if (port_a_reg[ADDR_WIDTH+DATA_WIDTH+1]) begin
            ram[port_a_reg[ADDR_WIDTH+DATA_WIDTH:ADDR_WIDTH+1]] <= port_a_reg[DATA_WIDTH:1];
        end
        if (port_b_reg[ADDR_WIDTH+DATA_WIDTH+1]) begin
            ram[port_b_reg[ADDR_WIDTH+DATA_WIDTH:ADDR_WIDTH+1]] <= port_b_reg[DATA_WIDTH:1];
        end
    end

    // 读操作流水线，使用位选择优化
    always @(posedge clk) begin
        dout_a <= ram[port_a_reg[ADDR_WIDTH+DATA_WIDTH:ADDR_WIDTH+1]];
        dout_b <= ram[port_b_reg[ADDR_WIDTH+DATA_WIDTH:ADDR_WIDTH+1]];
    end

endmodule