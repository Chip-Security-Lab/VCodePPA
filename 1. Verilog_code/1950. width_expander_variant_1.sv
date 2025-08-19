//SystemVerilog
module width_expander #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32  // 必须是IN_WIDTH的整数倍
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   valid_in,
    input  wire [IN_WIDTH-1:0]    data_in,
    output reg  [OUT_WIDTH-1:0]   data_out,
    output reg                    valid_out
);

    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    reg [$clog2(RATIO)-1:0] count_reg;
    reg [OUT_WIDTH-1:0] buffer_reg;

    // --- 前向重定时：将输入缓冲寄存器后移到组合逻辑之后 ---
    wire valid_in_high_fanout;
    wire rst_high_fanout;

    assign valid_in_high_fanout = valid_in;
    assign rst_high_fanout = rst;

    reg valid_in_pipeline;
    reg rst_pipeline;

    // 组合逻辑搬移到输入寄存器前，寄存器后移
    wire [OUT_WIDTH-1:0] buffer_next;
    wire [$clog2(RATIO)-1:0] count_next;
    wire [OUT_WIDTH-1:0] data_out_next;
    wire valid_out_next;

    assign buffer_next = (valid_in_high_fanout) ?
                        {buffer_reg[OUT_WIDTH-IN_WIDTH-1:0], data_in} :
                        buffer_reg;

    assign count_next = (rst_high_fanout) ? {($clog2(RATIO)){1'b0}} :
                        (valid_in_high_fanout && (count_reg == RATIO-1)) ? {($clog2(RATIO)){1'b0}} :
                        (valid_in_high_fanout) ? count_reg + 1'b1 :
                        count_reg;

    assign data_out_next = (rst_high_fanout) ? {OUT_WIDTH{1'b0}} :
                           (valid_in_high_fanout && (count_reg == RATIO-1)) ? {buffer_reg[OUT_WIDTH-IN_WIDTH-1:0], data_in} :
                           data_out;

    assign valid_out_next = (rst_high_fanout) ? 1'b0 :
                            (valid_in_high_fanout && (count_reg == RATIO-1)) ? 1'b1 :
                            1'b0;

    always @(posedge clk) begin
        valid_in_pipeline <= valid_in_high_fanout;
        rst_pipeline <= rst_high_fanout;
        count_reg <= count_next;
        buffer_reg <= buffer_next;
        data_out <= data_out_next;
        valid_out <= valid_out_next;
    end

endmodule