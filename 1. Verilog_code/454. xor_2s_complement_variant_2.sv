//SystemVerilog
module xor_2s_complement (
    input  wire        clk,       // 系统时钟
    input  wire        rst_n,     // 低电平有效复位
    input  wire        data_valid, // 输入数据有效信号
    input  wire [3:0]  data_in,    // 4位输入数据
    output reg  [3:0]  xor_out,    // 4位异或结果
    output reg         out_valid   // 输出数据有效信号
);

    // 内部信号定义 - 更深的流水线级
    reg [3:0] data_stage1;
    reg       valid_stage1;
    reg [3:0] data_stage2;
    reg       valid_stage2;
    reg [1:0] xor_stage1;
    reg [1:0] xor_stage2;
    reg [1:0] xor_stage3;
    
    // 常量定义 - 提高可读性
    localparam XOR_MASK_LOW  = 2'b11;
    localparam XOR_MASK_HIGH = 2'b11;
    
    // 第一级流水线 - 寄存数据，分离高低位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1  <= 4'b0000;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1  <= data_in;
            valid_stage1 <= data_valid;
        end
    end
    
    // 第二级流水线 - 处理低2位异或运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2   <= 4'b0000;
            valid_stage2  <= 1'b0;
            xor_stage1    <= 2'b00;
        end else begin
            data_stage2   <= data_stage1;
            valid_stage2  <= valid_stage1;
            xor_stage1    <= data_stage1[1:0] ^ XOR_MASK_LOW;
        end
    end
    
    // 第三级流水线 - 处理高2位异或运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage2    <= 2'b00;
            xor_stage3    <= 2'b00;
            out_valid     <= 1'b0;
        end else begin
            xor_stage2    <= data_stage2[3:2] ^ XOR_MASK_HIGH;
            xor_stage3    <= xor_stage1;
            out_valid     <= valid_stage2;
        end
    end
    
    // 最终输出 - 合并高低位异或结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_out   <= 4'b0000;
        end else begin
            xor_out   <= {xor_stage2, xor_stage3};
        end
    end

endmodule