//SystemVerilog
module pipeline_regfile #(
    parameter DW = 64,
    parameter AW = 3,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// 使用初始化值声明
reg [DW-1:0] mem [0:DEPTH-1];
reg [DW-1:0] pipe_reg1 = {DW{1'b0}};
reg [DW-1:0] pipe_reg2 = {DW{1'b0}};
reg [AW-1:0] addr_r1 = {AW{1'b0}};
reg [AW-1:0] addr_r2 = {AW{1'b0}};
reg wr_en_r1 = 1'b0;
integer i;

// 优化寄存器和存储器访问逻辑
always @(posedge clk) begin
    if (rst) begin
        // 将for循环转换为while循环
        i = 0;
        while (i < DEPTH) begin
            mem[i] <= {DW{1'b0}};
            i = i + 1;
        end
        
        pipe_reg1 <= {DW{1'b0}};
        pipe_reg2 <= {DW{1'b0}};
        addr_r1 <= {AW{1'b0}};
        addr_r2 <= {AW{1'b0}};
        wr_en_r1 <= 1'b0;
    end else begin
        // 地址和写使能寄存
        addr_r1 <= addr;
        addr_r2 <= addr_r1;
        wr_en_r1 <= wr_en;
        
        // 写操作
        if (wr_en) 
            mem[addr] <= din;
            
        // 读操作和流水线内转发 - 优化冗余逻辑
        pipe_reg2 <= pipe_reg1;
        
        // 第一级流水线，包含数据转发逻辑
        if (wr_en && (addr == addr_r1))
            pipe_reg1 <= din;
        else
            pipe_reg1 <= mem[addr];
    end
end

// 数据输出
assign dout = pipe_reg2;

endmodule