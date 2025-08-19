//SystemVerilog
// 顶层模块
module gray_counter #(parameter W=4) (
    input clk, rstn,
    output [W-1:0] gray
);
    wire [W-1:0] bin;
    wire [W-1:0] next_bin;
    wire [W-1:0] gray_out;
    
    // 二进制计数器子模块
    binary_counter #(
        .WIDTH(W)
    ) bin_counter_inst (
        .clk(clk),
        .rstn(rstn),
        .bin_out(bin),
        .next_bin(next_bin)
    );
    
    // 二进制到格雷码转换器子模块
    bin2gray_converter #(
        .WIDTH(W)
    ) converter_inst (
        .bin_in(next_bin),
        .gray_out(gray_out)
    );
    
    // 输出寄存器子模块
    output_register #(
        .WIDTH(W)
    ) out_reg_inst (
        .clk(clk),
        .rstn(rstn),
        .gray_in(gray_out),
        .gray_out(gray)
    );
endmodule

// 二进制计数器子模块
module binary_counter #(parameter WIDTH=4) (
    input clk,
    input rstn,
    output reg [WIDTH-1:0] bin_out,
    output [WIDTH-1:0] next_bin
);
    assign next_bin = bin_out + 1'b1;
    
    always @(posedge clk) begin
        if (!rstn) begin
            bin_out <= {WIDTH{1'b0}};
        end
        else begin
            bin_out <= next_bin;
        end
    end
endmodule

// 二进制到格雷码转换器子模块
module bin2gray_converter #(parameter WIDTH=4) (
    input [WIDTH-1:0] bin_in,
    output [WIDTH-1:0] gray_out
);
    // 桶形移位器实现右移1位
    wire [WIDTH-1:0] shifted_bin;
    
    // 使用多路复用器结构替代直接的(bin >> 1)
    assign shifted_bin = {1'b0, bin_in[WIDTH-1:1]};
    
    // 格雷码转换逻辑
    assign gray_out = shifted_bin ^ bin_in;
endmodule

// 输出寄存器子模块
module output_register #(parameter WIDTH=4) (
    input clk,
    input rstn,
    input [WIDTH-1:0] gray_in,
    output reg [WIDTH-1:0] gray_out
);
    always @(posedge clk) begin
        if (!rstn) begin
            gray_out <= {WIDTH{1'b0}};
        end
        else begin
            gray_out <= gray_in;
        end
    end
endmodule