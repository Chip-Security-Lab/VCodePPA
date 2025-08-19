//SystemVerilog
// 顶层模块
module clk_gate_addr #(parameter AW=2) (
    input clk,
    input rst_n,
    input en,
    input [AW-1:0] addr,
    input valid_in,
    output ready_out,
    output [2**AW-1:0] decode,
    output valid_out
);

    // 内部连线声明
    wire [AW-1:0] addr_stage1, addr_stage2;
    wire en_stage1, en_stage2;
    wire valid_stage1, valid_stage2;

    // 就绪信号常量
    assign ready_out = 1'b1;

    // 流水线第一级：地址预处理模块实例
    addr_preprocessor #(
        .AW(AW)
    ) stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .addr_in(addr),
        .en_in(en),
        .valid_in(valid_in),
        .addr_out(addr_stage1),
        .en_out(en_stage1),
        .valid_out(valid_stage1)
    );

    // 流水线第二级：计算阶段模块实例
    computation_stage #(
        .AW(AW)
    ) stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .addr_in(addr_stage1),
        .en_in(en_stage1),
        .valid_in(valid_stage1),
        .addr_out(addr_stage2),
        .en_out(en_stage2),
        .valid_out(valid_stage2)
    );

    // 流水线第三级：解码输出模块实例
    decoder_output #(
        .AW(AW)
    ) stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .addr_in(addr_stage2),
        .en_in(en_stage2),
        .valid_in(valid_stage2),
        .decode_out(decode),
        .valid_out(valid_out)
    );

endmodule

// 流水线第一级：地址预处理模块
module addr_preprocessor #(parameter AW=2) (
    input clk,
    input rst_n,
    input [AW-1:0] addr_in,
    input en_in,
    input valid_in,
    output reg [AW-1:0] addr_out,
    output reg en_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= {AW{1'b0}};
            en_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            en_out <= en_in;
            valid_out <= valid_in;
        end
    end

endmodule

// 流水线第二级：计算阶段模块
module computation_stage #(parameter AW=2) (
    input clk,
    input rst_n,
    input [AW-1:0] addr_in,
    input en_in,
    input valid_in,
    output reg [AW-1:0] addr_out,
    output reg en_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= {AW{1'b0}};
            en_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            addr_out <= addr_in;
            en_out <= en_in;
            valid_out <= valid_in;
        end
    end

endmodule

// 流水线第三级：解码输出模块
module decoder_output #(parameter AW=2) (
    input clk,
    input rst_n,
    input [AW-1:0] addr_in,
    input en_in,
    input valid_in,
    output reg [2**AW-1:0] decode_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_out <= {2**AW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            decode_out <= en_in ? (1'b1 << addr_in) : {2**AW{1'b0}};
            valid_out <= valid_in;
        end
    end

endmodule