//SystemVerilog
// 顶层模块
module gray_counter #(parameter W=4) (
    input  logic clk, rstn,
    output logic [W-1:0] gray
);
    // 内部信号连接
    logic [W-1:0] bin;
    logic [W-1:0] next_bin;
    logic [W-1:0] next_gray;
    
    // 二进制计数器子模块实例化
    binary_counter #(
        .WIDTH(W)
    ) bin_counter_inst (
        .clk      (clk),
        .rstn     (rstn),
        .bin      (bin),
        .next_bin (next_bin)
    );
    
    // 二进制到格雷码转换子模块实例化
    bin2gray_converter #(
        .WIDTH(W)
    ) converter_inst (
        .bin_value  (next_bin),
        .gray_value (next_gray)
    );
    
    // 格雷码输出寄存器子模块实例化
    output_register #(
        .WIDTH(W)
    ) output_reg_inst (
        .clk       (clk),
        .rstn      (rstn),
        .next_gray (next_gray),
        .gray      (gray)
    );
endmodule

// 二进制计数器子模块
module binary_counter #(parameter WIDTH=4) (
    input  logic clk, rstn,
    output logic [WIDTH-1:0] bin,
    output logic [WIDTH-1:0] next_bin
);
    // 计算下一个二进制值
    assign next_bin = bin + 1'b1;
    
    // 二进制计数器时序逻辑
    always_ff @(posedge clk) begin
        if (!rstn) begin
            bin <= '0;
        end
        else begin
            bin <= next_bin;
        end
    end
endmodule

// 二进制到格雷码转换子模块
module bin2gray_converter #(parameter WIDTH=4) (
    input  logic [WIDTH-1:0] bin_value,
    output logic [WIDTH-1:0] gray_value
);
    // 二进制到格雷码的组合逻辑转换
    assign gray_value = (bin_value >> 1) ^ bin_value;
endmodule

// 格雷码输出寄存器子模块
module output_register #(parameter WIDTH=4) (
    input  logic clk, rstn,
    input  logic [WIDTH-1:0] next_gray,
    output logic [WIDTH-1:0] gray
);
    // 格雷码输出寄存器
    always_ff @(posedge clk) begin
        if (!rstn) begin
            gray <= '0;
        end
        else begin
            gray <= next_gray;
        end
    end
endmodule