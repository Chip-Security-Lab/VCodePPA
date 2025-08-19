//SystemVerilog
// 顶层模块
module crossbar_sync_4x4 (
    input wire clk, rst_n,
    input wire [7:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output wire [7:0] out0, out1, out2, out3
);
    // 为高扇出信号添加缓冲寄存器
    reg [7:0] in0_buf1, in0_buf2;
    reg [7:0] in1_buf1, in1_buf2;
    reg [7:0] in2_buf1, in2_buf2;
    reg [7:0] in3_buf1, in3_buf2;
    
    // 时钟缓冲
    wire clk_buf1, clk_buf2;
    
    // 时钟缓冲器实例化
    clock_buffer clk_buffer_inst (
        .clk_in(clk),
        .clk_out1(clk_buf1),
        .clk_out2(clk_buf2)
    );
    
    // 输入缓冲寄存器
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            in0_buf1 <= 8'b0;
            in1_buf1 <= 8'b0;
            in2_buf1 <= 8'b0;
            in3_buf1 <= 8'b0;
        end else begin
            in0_buf1 <= in0;
            in1_buf1 <= in1;
            in2_buf1 <= in2;
            in3_buf1 <= in3;
        end
    end
    
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            in0_buf2 <= 8'b0;
            in1_buf2 <= 8'b0;
            in2_buf2 <= 8'b0;
            in3_buf2 <= 8'b0;
        end else begin
            in0_buf2 <= in0;
            in1_buf2 <= in1;
            in2_buf2 <= in2;
            in3_buf2 <= in3;
        end
    end
    
    // 内部连线声明
    wire [7:0] mux0_out, mux1_out, mux2_out, mux3_out;
    
    // 输入多路复用器实例化 - 使用缓冲输入信号
    input_mux mux0 (
        .sel(sel0),
        .in0(in0_buf1), .in1(in1_buf1), .in2(in2_buf1), .in3(in3_buf1),
        .out(mux0_out)
    );
    
    input_mux mux1 (
        .sel(sel1),
        .in0(in0_buf1), .in1(in1_buf1), .in2(in2_buf1), .in3(in3_buf1),
        .out(mux1_out)
    );
    
    input_mux mux2 (
        .sel(sel2),
        .in0(in0_buf2), .in1(in1_buf2), .in2(in2_buf2), .in3(in3_buf2),
        .out(mux2_out)
    );
    
    input_mux mux3 (
        .sel(sel3),
        .in0(in0_buf2), .in1(in1_buf2), .in2(in2_buf2), .in3(in3_buf2),
        .out(mux3_out)
    );
    
    // 输出寄存器实例化 - 使用缓冲时钟
    output_register out_reg (
        .clk(clk_buf2),
        .rst_n(rst_n),
        .in0(mux0_out), .in1(mux1_out), .in2(mux2_out), .in3(mux3_out),
        .out0(out0), .out1(out1), .out2(out2), .out3(out3)
    );
    
endmodule

// 时钟缓冲器模块
module clock_buffer (
    input wire clk_in,
    output wire clk_out1, clk_out2
);
    // 简单的时钟缓冲器实现
    // 在实际设计中，这通常由特定工艺库中的专用单元实现
    assign clk_out1 = clk_in;
    assign clk_out2 = clk_in;
endmodule

// 输入多路复用器子模块
module input_mux (
    input wire [1:0] sel,
    input wire [7:0] in0, in1, in2, in3,
    output reg [7:0] out
);
    // 将组合逻辑多路复用器改为always块，以提高可读性
    always @(*) begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            2'b11: out = in3;
            default: out = 8'b0;
        endcase
    end
endmodule

// 输出寄存器子模块
module output_register (
    input wire clk, rst_n,
    input wire [7:0] in0, in1, in2, in3,
    output reg [7:0] out0, out1, out2, out3
);
    // 同步输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out0 <= 8'b0;
            out1 <= 8'b0;
            out2 <= 8'b0;
            out3 <= 8'b0;
        end else begin
            out0 <= in0;
            out1 <= in1;
            out2 <= in2;
            out3 <= in3;
        end
    end
endmodule