//SystemVerilog
// 顶层模块
module signed2unsigned_unit #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 data_valid_in,
    input  wire [WIDTH-1:0]     signed_in,
    output reg  [WIDTH-1:0]     unsigned_out,
    output reg                  overflow,
    output reg                  data_valid_out
);

    // 内部信号定义
    wire [WIDTH-1:0]   signed_in_reg;
    wire               data_valid_stage1;
    wire [WIDTH-1:0]   offset;
    wire [WIDTH-1:0]   unsigned_out_wire;
    wire               overflow_wire;

    // 实例化输入寄存器模块
    input_reg_stage #(
        .WIDTH(WIDTH)
    ) u_input_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_in(data_valid_in),
        .signed_in(signed_in),
        .signed_in_reg(signed_in_reg),
        .data_valid_stage1(data_valid_stage1)
    );

    // 实例化转换计算模块
    conversion_calc #(
        .WIDTH(WIDTH)
    ) u_conversion (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_stage1(data_valid_stage1),
        .signed_in_reg(signed_in_reg),
        .unsigned_out(unsigned_out_wire),
        .overflow(overflow_wire)
    );

    // 实例化输出寄存器模块
    output_reg_stage #(
        .WIDTH(WIDTH)
    ) u_output_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid_stage1(data_valid_stage1),
        .unsigned_out_wire(unsigned_out_wire),
        .overflow_wire(overflow_wire),
        .unsigned_out(unsigned_out),
        .overflow(overflow),
        .data_valid_out(data_valid_out)
    );

endmodule

// 输入寄存器模块
module input_reg_stage #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 data_valid_in,
    input  wire [WIDTH-1:0]     signed_in,
    output reg  [WIDTH-1:0]     signed_in_reg,
    output reg                  data_valid_stage1
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            signed_in_reg <= {WIDTH{1'b0}};
            data_valid_stage1 <= 1'b0;
        end else begin
            signed_in_reg <= signed_in;
            data_valid_stage1 <= data_valid_in;
        end
    end

endmodule

// 转换计算模块
module conversion_calc #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 data_valid_stage1,
    input  wire [WIDTH-1:0]     signed_in_reg,
    output reg  [WIDTH-1:0]     unsigned_out,
    output reg                  overflow
);

    wire [WIDTH-1:0] offset = {1'b1, {(WIDTH-1){1'b0}}};

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            unsigned_out <= {WIDTH{1'b0}};
            overflow <= 1'b0;
        end else if (data_valid_stage1) begin
            unsigned_out <= signed_in_reg + offset;
            overflow <= signed_in_reg[WIDTH-1];
        end
    end

endmodule

// 输出寄存器模块
module output_reg_stage #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 data_valid_stage1,
    input  wire [WIDTH-1:0]     unsigned_out_wire,
    input  wire                 overflow_wire,
    output reg  [WIDTH-1:0]     unsigned_out,
    output reg                  overflow,
    output reg                  data_valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            unsigned_out <= {WIDTH{1'b0}};
            overflow <= 1'b0;
            data_valid_out <= 1'b0;
        end else begin
            unsigned_out <= unsigned_out_wire;
            overflow <= overflow_wire;
            data_valid_out <= data_valid_stage1;
        end
    end

endmodule