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
    
    // 优化比较逻辑，使用范围检查
    wire [7:0] period_half = i_period >> 1;
    wire [7:0] period_minus_one = i_period - 8'd1;
    wire counter_at_limit = (counter == period_minus_one);
    
    // 优化相位计算，避免使用模运算
    wire [7:0] phase_counter = (counter + i_phase) > period_minus_one ? 
                              (counter + i_phase - i_period) : (counter + i_phase);
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter <= 8'd0;
            out_reg <= 1'b0;
        end else begin
            if (counter_at_limit) begin
                counter <= 8'd0;
                out_reg <= ~out_reg;
            end else begin
                counter <= counter + 8'd1;
            end
        end
    end
    
    // 优化相位调整输出逻辑
    reg phase_adjusted_out;
    wire phase_compare = phase_counter < period_half;
    
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            phase_adjusted_out <= 1'b0;
        end else begin
            phase_adjusted_out <= phase_compare;
        end
    end
    
    // 优化相位控制选择逻辑
    wire use_phase_control = |i_phase;
    assign o_wave = use_phase_control ? phase_adjusted_out : out_reg;
    assign o_wave_n = ~o_wave;
endmodule