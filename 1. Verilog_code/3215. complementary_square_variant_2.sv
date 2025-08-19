//SystemVerilog
module complementary_square(
    input i_clk,
    input i_rst_n,
    input [7:0] i_period,
    input [7:0] i_phase,
    output o_wave,
    output o_wave_n
);
    reg [7:0] counter;
    reg out_reg;
    reg out_reg_n;
    wire period_end;
    
    assign period_end = (counter == i_period - 1'b1);
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter <= 8'd0;
            out_reg <= 1'b0;
            out_reg_n <= 1'b1;
        end else begin
            if (period_end) begin
                counter <= 8'd0;
                out_reg <= ~out_reg;
                out_reg_n <= ~out_reg_n;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    assign o_wave = out_reg;
    assign o_wave_n = out_reg_n;
endmodule