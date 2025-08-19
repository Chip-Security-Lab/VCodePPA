//SystemVerilog
module rom_dual_port #(parameter W=32, D=1024)(
    input clk,
    input rst_n,
    input [9:0] addr1,
    input [9:0] addr2,
    input valid_in,
    output reg valid_out,
    output reg [W-1:0] dout1,
    output reg [W-1:0] dout2
);
    // 声明双端口ROM存储器
    reg [W-1:0] content [0:D-1];
    
    // 流水线寄存器和控制信号
    reg [W-1:0] data1_stage1, data2_stage1;
    reg valid_stage1;
    
    // 添加缓冲寄存器以减少扇出
    reg [W-1:0] buffer1, buffer2;
    
    // 初始化一些值用于测试
    initial begin
        // 示例初始化，实际使用时应替换为具体值
        content[0] = 32'h00001111;
        content[1] = 32'h22223333;
        // $readmemh("dual_port.init", content); // 仿真中使用
    end
    
    // 流水线第一级 - 读取存储器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data1_stage1 <= {W{1'b0}};
            data2_stage1 <= {W{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data1_stage1 <= content[addr1];
            data2_stage1 <= content[addr2];
            valid_stage1 <= valid_in;
        end
    end
    
    // 添加缓冲寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer1 <= {W{1'b0}};
            buffer2 <= {W{1'b0}};
        end else begin
            buffer1 <= data1_stage1;
            buffer2 <= data2_stage1;
        end
    end
    
    // 流水线第二级 - 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout1 <= {W{1'b0}};
            dout2 <= {W{1'b0}};
            valid_out <= 1'b0;
        end else begin
            dout1 <= buffer1;
            dout2 <= buffer2;
            valid_out <= valid_stage1;
        end
    end
endmodule