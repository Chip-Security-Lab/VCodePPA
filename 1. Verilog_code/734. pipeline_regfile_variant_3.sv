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
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [DW-1:0] pipe_reg1, pipe_reg2;
    
    // 复位逻辑模块 - 处理存储器初始化
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DW{1'b0}};
            end
        end
    end
    
    // 写入逻辑模块 - 控制存储器写入
    always @(posedge clk) begin
        if (!rst && wr_en) begin
            mem[addr] <= din;
        end
    end
    
    // 管道寄存器1逻辑模块 - 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            pipe_reg1 <= {DW{1'b0}};
        end else begin
            pipe_reg1 <= mem[addr];
        end
    end
    
    // 管道寄存器2逻辑模块 - 第二级流水线
    always @(posedge clk) begin
        if (rst) begin
            pipe_reg2 <= {DW{1'b0}};
        end else begin
            pipe_reg2 <= pipe_reg1;
        end
    end
    
    // 输出赋值
    assign dout = pipe_reg2;
endmodule