//SystemVerilog
// 顶层模块
module HybridNOT(
    input clk,
    input rst_n,
    input [7:0] byte_in,
    input valid_in,
    output ready_out,
    output [7:0] byte_out,
    output valid_out,
    input ready_in
);
    // 将字节按照高低位分为两个4位操作
    wire [3:0] lower_nibble_in, upper_nibble_in;
    wire [3:0] lower_nibble_out, upper_nibble_out;
    
    // 内部状态控制
    reg data_valid_reg;
    reg [7:0] byte_in_reg;
    
    // 将输入分为高低两个半字节
    assign lower_nibble_in = byte_in_reg[3:0];
    assign upper_nibble_in = byte_in_reg[7:4];
    
    // 实例化取反子模块
    NibbleInverter lower_inverter (
        .nibble_in(lower_nibble_in),
        .nibble_out(lower_nibble_out)
    );
    
    NibbleInverter upper_inverter (
        .nibble_in(upper_nibble_in),
        .nibble_out(upper_nibble_out)
    );
    
    // 合并输出
    assign byte_out = {upper_nibble_out, lower_nibble_out};
    
    // Valid-Ready握手逻辑
    assign ready_out = !data_valid_reg || ready_in;
    assign valid_out = data_valid_reg;
    
    // 重置控制逻辑
    always @(negedge rst_n) begin
        if (!rst_n) begin
            data_valid_reg <= 1'b0;
            byte_in_reg <= 8'b0;
        end
    end
    
    // 数据输入寄存逻辑
    always @(posedge clk) begin
        if (rst_n && ready_out && valid_in) begin
            byte_in_reg <= byte_in;
        end
    end
    
    // 有效信号控制逻辑
    always @(posedge clk) begin
        if (rst_n) begin
            if (ready_out && valid_in) begin
                data_valid_reg <= 1'b1;
            end else if (valid_out && ready_in) begin
                data_valid_reg <= 1'b0;
            end
        end
    end
    
endmodule

// 半字节取反子模块
module NibbleInverter(
    input [3:0] nibble_in,
    output [3:0] nibble_out
);
    // 使用参数定义取反掩码，增强可配置性
    parameter [3:0] INVERT_MASK = 4'hF;
    
    // 位级并行取反操作，采用异或实现
    assign nibble_out = nibble_in ^ INVERT_MASK;
    
endmodule