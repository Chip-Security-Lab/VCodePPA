//SystemVerilog
module band_pass_filter #(
    parameter WIDTH = 12
)(
    input clk, arst,
    input [WIDTH-1:0] x_in,
    output reg [WIDTH-1:0] y_out
);

    // 组合逻辑部分
    reg [WIDTH-1:0] lp_out_reg;
    wire [WIDTH-1:0] hp_out;
    wire [WIDTH-1:0] lp_next;
    
    // 高通滤波器组合逻辑
    assign hp_out = x_in - lp_out_reg;
    
    // 低通滤波器组合逻辑
    assign lp_next = lp_out_reg + ((x_in - lp_out_reg) >>> 3);

    // 时序逻辑部分
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            lp_out_reg <= 0;
            y_out <= 0;
        end else begin
            lp_out_reg <= lp_next;
            y_out <= hp_out;
        end
    end

endmodule