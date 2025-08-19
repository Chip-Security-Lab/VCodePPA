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
    wire counter_overflow;
    
    // 优化计数器控制逻辑
    assign counter_overflow = (counter == i_period - 1'b1);
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter <= 8'd0;
            out_reg <= 1'b0;
        end else begin
            counter <= counter_overflow ? 8'd0 : counter + 1'b1;
            out_reg <= counter_overflow ? ~out_reg : out_reg;
        end
    end
    
    // 输出赋值
    assign o_wave = out_reg;
    assign o_wave_n = ~out_reg;
endmodule