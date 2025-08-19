module prog_clock_gen(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output reg o_clk
);
    reg [15:0] count;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            count <= 16'd0;
            o_clk <= 1'b0;
        end else if (i_enable) begin
            if (count >= i_divisor - 1) begin
                count <= 16'd0;
                o_clk <= ~o_clk;
            end else
                count <= count + 16'd1;
        end
    end
endmodule