//SystemVerilog
//IEEE 1364-2005 Verilog
module decoder_sync_reg (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [3:0] addr,
    output reg [15:0] decoded
);
    // 内部连线，连接组合逻辑和时序逻辑
    wire [15:0] decode_value;
    wire [15:0] decode_value_buffered;
    
    // 实例化组合逻辑解码器模块
    decoder_comb decoder_unit (
        .addr(addr),
        .decode_value(decode_value)
    );
    
    // 实例化缓冲器模块
    decoder_buffer buffer_unit (
        .clk(clk),
        .rst_n(rst_n),
        .decode_value_in(decode_value),
        .decode_value_out(decode_value_buffered)
    );
    
    // 时序逻辑部分 - 仅处理最终输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decoded <= 16'h0000;
        else if (en)
            decoded <= decode_value_buffered;
    end
endmodule

// 纯组合逻辑模块 - 只负责解码功能
module decoder_comb (
    input wire [3:0] addr,
    output reg [15:0] decode_value
);
    // 组合逻辑部分 - 解码逻辑
    always @(*) begin
        case (addr)
            4'h0: decode_value = 16'h0001;
            4'h1: decode_value = 16'h0002;
            4'h2: decode_value = 16'h0004;
            4'h3: decode_value = 16'h0008;
            4'h4: decode_value = 16'h0010;
            4'h5: decode_value = 16'h0020;
            4'h6: decode_value = 16'h0040;
            4'h7: decode_value = 16'h0080;
            4'h8: decode_value = 16'h0100;
            4'h9: decode_value = 16'h0200;
            4'ha: decode_value = 16'h0400;
            4'hb: decode_value = 16'h0800;
            4'hc: decode_value = 16'h1000;
            4'hd: decode_value = 16'h2000;
            4'he: decode_value = 16'h4000;
            4'hf: decode_value = 16'h8000;
            default: decode_value = 16'h0000;
        endcase
    end
endmodule

// 缓冲寄存器模块 - 处理扇出负载分散
module decoder_buffer (
    input wire clk,
    input wire rst_n,
    input wire [15:0] decode_value_in,
    output wire [15:0] decode_value_out
);
    // 分段处理缓冲以降低每个寄存器的扇出负载
    reg [3:0] buf_section1;
    reg [3:0] buf_section2;
    reg [3:0] buf_section3;
    reg [3:0] buf_section4;
    
    // 时序逻辑部分 - 缓冲寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf_section1 <= 4'h0;
            buf_section2 <= 4'h0;
            buf_section3 <= 4'h0;
            buf_section4 <= 4'h0;
        end else begin
            buf_section1 <= decode_value_in[3:0];
            buf_section2 <= decode_value_in[7:4];
            buf_section3 <= decode_value_in[11:8];
            buf_section4 <= decode_value_in[15:12];
        end
    end
    
    // 使用连续赋值将分段缓冲合并为输出
    assign decode_value_out = {buf_section4, buf_section3, buf_section2, buf_section1};
endmodule