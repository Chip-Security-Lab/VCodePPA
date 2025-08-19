//SystemVerilog
module des_cbc_async (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号，低电平有效
    
    // 输入数据接口 (Valid-Ready握手)
    input wire [63:0] din,   // 输入数据
    input wire [63:0] iv,    // 初始向量
    input wire [55:0] key,   // 密钥
    input wire        valid_in, // 输入数据有效信号
    output reg        ready_in, // 输入就绪信号
    
    // 输出数据接口 (Valid-Ready握手)
    output reg [63:0] dout,     // 输出数据
    output reg        valid_out, // 输出数据有效信号
    input wire        ready_out  // 输出就绪信号
);

    // 内部信号 - 使用线网替代一些寄存器以实现前向重定时
    wire [63:0] xor_stage;
    reg [63:0] feistel_in_reg;
    reg [63:0] feistel_out;
    reg        processing;
    
    // 组合逻辑前移 - XOR操作不再在寄存器中
    assign xor_stage = din ^ iv;

    // 握手逻辑和数据处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_in   <= 1'b1;
            valid_out  <= 1'b0;
            dout       <= 64'b0;
            processing <= 1'b0;
            feistel_in_reg <= 64'b0;
        end else begin
            // 输入握手处理 - 寄存器移动到组合逻辑之后
            if (valid_in && ready_in) begin
                feistel_in_reg <= xor_stage; // 寄存器移到XOR操作之后
                ready_in      <= 1'b0;
                processing    <= 1'b1;
            end
            
            // 处理阶段
            if (processing) begin
                // 简化的Feistel网络 - 现在处理前一阶段的数据
                feistel_out <= {feistel_in_reg[31:0], feistel_in_reg[63:32] ^ key[31:0]};
                dout <= {feistel_out[15:0], feistel_out[63:16]};
                valid_out <= 1'b1;
                processing <= 1'b0;
            end
            
            // 输出握手处理
            if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                ready_in  <= 1'b1;  // 准备接收下一个输入
            end
        end
    end

endmodule