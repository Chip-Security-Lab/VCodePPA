//SystemVerilog
//IEEE 1364-2005 Verilog标准
module counter_gray #(parameter BITS=4) (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    output wire [BITS-1:0] gray
);
    wire [BITS-1:0] bin;
    wire [BITS-1:0] shifted_bin;
    wire [BITS-1:0] bin_buffered;
    wire [BITS-1:0] shifted_bin_buffered;
    
    // 二进制计数器子模块
    binary_counter #(
        .WIDTH(BITS)
    ) u_binary_counter (
        .clk     (clk),
        .rst_n   (rst_n),
        .en      (en),
        .count   (bin)
    );
    
    // 信号缓冲子模块
    signal_buffer #(
        .WIDTH(BITS)
    ) u_signal_buffer (
        .clk              (clk),
        .rst_n            (rst_n),
        .bin_in           (bin),
        .shifted_bin_in   (shifted_bin),
        .bin_out          (bin_buffered),
        .shifted_bin_out  (shifted_bin_buffered)
    );
    
    // 桶形移位器子模块
    barrel_shifter #(
        .WIDTH(BITS)
    ) u_barrel_shifter (
        .bin_in        (bin_buffered),
        .shifted_bin   (shifted_bin)
    );
    
    // Gray码转换器子模块
    gray_converter #(
        .WIDTH(BITS)
    ) u_gray_converter (
        .bin_in          (bin_buffered),
        .shifted_bin_in  (shifted_bin_buffered),
        .gray_out        (gray)
    );
endmodule

//二进制计数器子模块
module binary_counter #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    output reg  [WIDTH-1:0] count
);
    // 二进制计数器实现
    always @(posedge clk) begin
        if (!rst_n) 
            count <= {WIDTH{1'b0}};
        else if (en) 
            count <= count + 1'b1;
    end
endmodule

//信号缓冲子模块
module signal_buffer #(
    parameter WIDTH = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] bin_in,
    input  wire [WIDTH-1:0] shifted_bin_in,
    output reg  [WIDTH-1:0] bin_out,
    output reg  [WIDTH-1:0] shifted_bin_out
);
    // 低半部分缓冲
    reg [WIDTH-1:0] bin_buf1;
    // 高半部分缓冲
    reg [WIDTH-1:0] bin_buf2;
    
    // 缓冲寄存器更新
    always @(posedge clk) begin
        if (!rst_n) begin
            bin_buf1 <= {WIDTH{1'b0}};
            bin_buf2 <= {WIDTH{1'b0}};
            shifted_bin_out <= {WIDTH{1'b0}};
        end else begin
            bin_buf1 <= bin_in;
            bin_buf2 <= bin_in;
            shifted_bin_out <= shifted_bin_in;
        end
    end
    
    // 输出赋值
    assign bin_out = bin_buf1;
endmodule

//桶形移位器子模块
module barrel_shifter #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] bin_in,
    output wire [WIDTH-1:0] shifted_bin
);
    // MSB移位后为0
    assign shifted_bin[WIDTH-1] = 1'b0;
    
    // 使用参数化生成块进行桶形移位
    genvar i;
    generate
        for (i = 0; i < WIDTH-1; i = i + 1) begin : BARREL_SHIFTER
            // 分割高低半部分以减少扇出
            if (i < (WIDTH-1)/2) begin : LOW_HALF
                assign shifted_bin[i] = bin_in[i+1];
            end else begin : HIGH_HALF
                assign shifted_bin[i] = bin_in[i+1];
            end
        end
    endgenerate
endmodule

//Gray码转换器子模块
module gray_converter #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] bin_in,
    input  wire [WIDTH-1:0] shifted_bin_in,
    output wire [WIDTH-1:0] gray_out
);
    // Gray码生成 - 二进制值与其右移1位的值进行异或
    assign gray_out = bin_in ^ shifted_bin_in;
endmodule