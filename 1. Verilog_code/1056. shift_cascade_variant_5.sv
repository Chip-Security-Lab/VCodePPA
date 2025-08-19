//SystemVerilog
module shift_cascade #(parameter WIDTH=8, DEPTH=4) (
    input clk,
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);

wire [WIDTH-1:0] binary_sub_in0;
wire [WIDTH-1:0] binary_sub_in1;
wire [WIDTH-1:0] binary_sub_out0;
wire [WIDTH-1:0] binary_sub_out1;
wire [WIDTH-1:0] binary_sub_out2;
wire [WIDTH-1:0] binary_sub_out3;

// 第一阶段：直接输入
assign binary_sub_in0 = data_in;

// 第二阶段：补码减法
assign binary_sub_in1 = (DEPTH > 1) ? binary_sub_in0 : {WIDTH{1'b0}};
binary_subtractor #(.WIDTH(WIDTH)) u_sub0 (
    .a(binary_sub_in1),
    .b({WIDTH{1'b0}}),
    .diff(binary_sub_out0)
);

// 第三阶段
wire [WIDTH-1:0] stage2_input;
assign stage2_input = (DEPTH > 2) ? binary_sub_out0 : {WIDTH{1'b0}};
binary_subtractor #(.WIDTH(WIDTH)) u_sub1 (
    .a(stage2_input),
    .b({WIDTH{1'b0}}),
    .diff(binary_sub_out1)
);

// 第四阶段
wire [WIDTH-1:0] stage3_input;
assign stage3_input = (DEPTH > 3) ? binary_sub_out1 : {WIDTH{1'b0}};
binary_subtractor #(.WIDTH(WIDTH)) u_sub2 (
    .a(stage3_input),
    .b({WIDTH{1'b0}}),
    .diff(binary_sub_out2)
);

// 寄存器级
reg [WIDTH-1:0] reg_stage0;
reg [WIDTH-1:0] reg_stage1;
reg [WIDTH-1:0] reg_stage2;
reg [WIDTH-1:0] reg_stage3;

always @(posedge clk) begin
    if (en) begin
        reg_stage0 <= binary_sub_in0;
        if (DEPTH > 1) reg_stage1 <= binary_sub_out0;
        if (DEPTH > 2) reg_stage2 <= binary_sub_out1;
        if (DEPTH > 3) reg_stage3 <= binary_sub_out2;
    end
end

assign data_out = (DEPTH == 1) ? reg_stage0 :
                  (DEPTH == 2) ? reg_stage1 :
                  (DEPTH == 3) ? reg_stage2 : reg_stage3;

endmodule

module binary_subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff
);
    wire [WIDTH-1:0] b_complement;
    wire [WIDTH:0] sum_with_carry;
    assign b_complement = ~b;
    assign sum_with_carry = {1'b0, a} + {1'b0, b_complement} + 1'b1;
    assign diff = sum_with_carry[WIDTH-1:0];
endmodule