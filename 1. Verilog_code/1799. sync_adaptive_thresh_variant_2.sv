//SystemVerilog
module sync_adaptive_thresh #(
    parameter DW = 8
)(
    input clk, rst,
    input [DW-1:0] signal_in,
    input [DW-1:0] background,
    input [DW-1:0] sensitivity,
    output reg out_bit
);
    reg [DW-1:0] signal_in_reg;
    reg [DW-1:0] background_reg;
    reg [DW-1:0] sensitivity_reg;
    wire [DW-1:0] threshold;
    wire comparison_result;
    
    // 输入寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            signal_in_reg <= {DW{1'b0}};
            background_reg <= {DW{1'b0}};
            sensitivity_reg <= {DW{1'b0}};
        end else begin
            signal_in_reg <= signal_in;
            background_reg <= background;
            sensitivity_reg <= sensitivity;
        end
    end
    
    // 组合逻辑部分
    thresh_compare #(
        .DW(DW)
    ) thresh_compare_inst (
        .signal_in(signal_in_reg),
        .background(background_reg),
        .sensitivity(sensitivity_reg),
        .comparison_result(comparison_result)
    );
    
    // 输出寄存器
    always @(posedge clk or posedge rst) begin
        if (rst)
            out_bit <= 1'b0;
        else
            out_bit <= comparison_result;
    end
endmodule

module thresh_compare #(
    parameter DW = 8
)(
    input [DW-1:0] signal_in,
    input [DW-1:0] background,
    input [DW-1:0] sensitivity,
    output comparison_result
);
    wire [DW-1:0] threshold;
    
    assign threshold = background + sensitivity;
    assign comparison_result = (signal_in > threshold) ? 1'b1 : 1'b0;
endmodule