//SystemVerilog
// 顶层模块
module fully_registered_decoder(
    input clk,
    input rst,
    input [2:0] addr_in,
    output [7:0] decode_out
);
    // 内部连接信号
    wire [2:0] addr_stage1;
    wire valid_stage1;
    wire [2:0] addr_stage2;
    wire valid_stage2;
    wire [7:0] decode_stage3;
    wire valid_stage3;
    
    // 实例化输入寄存器模块
    input_stage input_reg (
        .clk(clk),
        .rst(rst),
        .addr_in(addr_in),
        .addr_out(addr_stage1),
        .valid_out(valid_stage1)
    );
    
    // 实例化地址处理模块
    address_processing_stage addr_proc (
        .clk(clk),
        .rst(rst),
        .addr_in(addr_stage1),
        .valid_in(valid_stage1),
        .addr_out(addr_stage2),
        .valid_out(valid_stage2)
    );
    
    // 实例化解码逻辑和寄存器模块
    decoding_stage decoder (
        .clk(clk),
        .rst(rst),
        .addr_in(addr_stage2),
        .valid_in(valid_stage2),
        .decode_out(decode_stage3),
        .valid_out(valid_stage3)
    );
    
    // 实例化输出寄存器模块
    output_stage output_reg (
        .clk(clk),
        .rst(rst),
        .decode_in(decode_stage3),
        .valid_in(valid_stage3),
        .decode_out(decode_out)
    );
endmodule

// 第一阶段：输入寄存模块
module input_stage (
    input clk,
    input rst,
    input [2:0] addr_in,
    output reg [2:0] addr_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            addr_out <= 3'b000;
            valid_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            valid_out <= 1'b1; // Always valid after reset
        end
    end
endmodule

// 第二阶段：地址处理模块
module address_processing_stage (
    input clk,
    input rst,
    input [2:0] addr_in,
    input valid_in,
    output reg [2:0] addr_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            addr_out <= 3'b000;
            valid_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            valid_out <= valid_in;
        end
    end
endmodule

// 第三阶段：解码逻辑模块
module decoding_stage (
    input clk,
    input rst,
    input [2:0] addr_in,
    input valid_in,
    output reg [7:0] decode_out,
    output reg valid_out
);
    always @(posedge clk) begin
        if (rst) begin
            decode_out <= 8'b00000000;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            decode_out <= (8'b00000001 << addr_in);
            valid_out <= valid_in;
        end
    end
endmodule

// 第四阶段：输出寄存模块
module output_stage (
    input clk,
    input rst,
    input [7:0] decode_in,
    input valid_in,
    output reg [7:0] decode_out
);
    always @(posedge clk) begin
        if (rst) begin
            decode_out <= 8'b00000000;
        end else if (valid_in) begin
            decode_out <= decode_in;
        end
    end
endmodule