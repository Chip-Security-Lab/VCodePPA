//SystemVerilog
module param_square_wave #(
    parameter WIDTH = 16
)(
    input clock_i,
    input reset_i,
    input [WIDTH-1:0] period_i,
    input [WIDTH-1:0] duty_i,
    output reg wave_o
);
    reg [WIDTH-1:0] counter_r;
    wire period_end;
    wire [WIDTH-1:0] period_minus_1;
    wire [WIDTH-1:0] period_minus_1_inv;
    wire [WIDTH-1:0] period_minus_1_final;
    wire borrow;
    
    // 条件反相减法器实现
    assign period_minus_1_inv = ~period_i;
    assign {borrow, period_minus_1_final} = period_minus_1_inv + 1'b1;
    assign period_minus_1 = borrow ? period_minus_1_final : period_i;
    
    assign period_end = (counter_r == period_minus_1);
    
    always @(posedge clock_i) begin
        if (reset_i)
            counter_r <= {WIDTH{1'b0}};
        else if (period_end)
            counter_r <= {WIDTH{1'b0}};
        else
            counter_r <= counter_r + 1'b1;
    end
    
    always @(posedge clock_i) begin
        if (reset_i)
            wave_o <= 1'b0;
        else
            wave_o <= (counter_r < duty_i);
    end
endmodule