module subtractor_pipeline (
    input wire clk,
    input wire reset,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] res
);

// 流水线控制信号
wire [7:0] stage1_diff;
wire stage1_valid;
wire [7:0] stage2_diff;
wire stage2_valid;

// 实例化第一级流水线
stage1_pipe stage1_inst (
    .clk(clk),
    .reset(reset),
    .a_in(a),
    .b_in(b),
    .diff_out(stage1_diff),
    .valid_out(stage1_valid)
);

// 实例化第二级流水线
stage2_pipe stage2_inst (
    .clk(clk),
    .reset(reset),
    .a_in(stage1_diff),
    .valid_in(stage1_valid),
    .diff_out(stage2_diff),
    .valid_out(stage2_valid)
);

// 输出级逻辑
always @(posedge clk or posedge reset) begin
    if (reset) begin
        res <= 8'b0;
    end else if (stage2_valid) begin
        res <= stage2_diff;
    end
end

endmodule

// 第一级流水线模块
module stage1_pipe (
    input wire clk,
    input wire reset,
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    output reg [7:0] diff_out,
    output reg valid_out
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        diff_out <= 8'b0;
        valid_out <= 1'b0;
    end else begin
        diff_out <= a_in - b_in;
        valid_out <= 1'b1;
    end
end

endmodule

// 第二级流水线模块
module stage2_pipe (
    input wire clk,
    input wire reset,
    input wire [7:0] a_in,
    input wire valid_in,
    output reg [7:0] diff_out,
    output reg valid_out
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        diff_out <= 8'b0;
        valid_out <= 1'b0;
    end else begin
        diff_out <= a_in;
        valid_out <= valid_in;
    end
end

endmodule