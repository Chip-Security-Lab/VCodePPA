//SystemVerilog
module pll_clock_gen(
    input refclk,
    input reset,
    input [3:0] mult_factor,
    input [3:0] div_factor,
    output reg outclk
);
    reg [3:0] mult_count;
    wire mult_threshold_reached;
    
    // 使用比较器优化比较链
    assign mult_threshold_reached = (mult_count == (mult_factor - 1'b1));
    
    always @(posedge refclk or posedge reset) begin
        if (reset) begin
            mult_count <= 4'd0;
            outclk <= 1'b0;
        end else if (!reset && mult_threshold_reached) begin
            mult_count <= 4'd0;
            outclk <= ~outclk;
        end else if (!reset && !mult_threshold_reached) begin
            mult_count <= mult_count + 1'b1;
        end
    end
endmodule