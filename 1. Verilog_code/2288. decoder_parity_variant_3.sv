//SystemVerilog
module decoder_parity (
    input wire clk,           // 时钟信号 - 增加用于流水线
    input wire rst_n,         // 复位信号 - 增加用于流水线控制
    input wire [4:0] addr_in, // [4]=parity, [3:0]=address
    output reg valid,         // 有效性指示信号 - 改为寄存器输出
    output reg [7:0] decoded  // 解码后的数据 - 改为寄存器输出
);
    // 阶段1: 计算和验证奇偶校验
    reg parity_valid_stage1;
    reg [3:0] addr_stage1;
    wire computed_parity;
    
    // 数据流路径1: 计算奇偶校验位
    assign computed_parity = addr_in[0] ^ addr_in[1] ^ addr_in[2] ^ addr_in[3];
    
    // 第一阶段流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_valid_stage1 <= 1'b0;
            addr_stage1 <= 4'b0;
        end else begin
            // 比较计算的奇偶校验位与输入的奇偶校验位
            parity_valid_stage1 <= (computed_parity == addr_in[4]);
            addr_stage1 <= addr_in[3:0];
        end
    end
    
    // 阶段2: 根据奇偶校验结果进行解码
    reg [7:0] decoded_data;
    
    // 数据流路径2: 地址解码
    always @(*) begin
        decoded_data = 8'h0;
        if (parity_valid_stage1)
            decoded_data = (8'h01 << addr_stage1);
    end
    
    // 第二阶段流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
            decoded <= 8'h0;
        end else begin
            valid <= parity_valid_stage1;
            decoded <= decoded_data;
        end
    end
    
endmodule