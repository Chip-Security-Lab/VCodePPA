//SystemVerilog
module pll_clock_gen(
    input refclk,
    input reset,
    input [3:0] mult_factor,
    input [3:0] div_factor,
    output outclk
);
    wire mult_clk;
    
    // 乘法器子模块实例化
    frequency_multiplier u_freq_mult (
        .clk_in(refclk),
        .reset(reset),
        .mult_factor(mult_factor),
        .clk_out(mult_clk)
    );
    
    // 分频器子模块实例化
    frequency_divider u_freq_div (
        .clk_in(mult_clk),
        .reset(reset),
        .div_factor(div_factor),
        .clk_out(outclk)
    );
    
endmodule

module frequency_multiplier (
    input clk_in,
    input reset,
    input [3:0] mult_factor,
    output reg clk_out
);
    reg [3:0] count;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            count <= 4'd0;
            clk_out <= 1'b0;
        end else if (count >= mult_factor - 1) begin
            count <= 4'd0;
            clk_out <= ~clk_out;
        end else
            count <= count + 1'b1;
    end
endmodule

module frequency_divider (
    input clk_in,
    input reset,
    input [3:0] div_factor,
    output reg clk_out
);
    reg [3:0] count;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            count <= 4'd0;
            clk_out <= 1'b0;
        end else if (count >= div_factor - 1) begin
            count <= 4'd0;
            clk_out <= ~clk_out;
        end else
            count <= count + 1'b1;
    end
endmodule