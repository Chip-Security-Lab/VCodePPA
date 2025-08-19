//SystemVerilog
module sweep_square(
    input clk,
    input rst,
    input [7:0] start_period,
    input [7:0] end_period,
    input [15:0] sweep_rate,
    output reg sq_out
);
    reg [7:0] period;
    reg [7:0] counter;
    reg [15:0] sweep_counter;
    reg sweep_dir;  // 0: increasing frequency, 1: decreasing
    
    // 预计算比较结果，减少关键路径延迟
    wire counter_eq_period_m1 = (counter == period - 8'd1);
    wire sweep_counter_eq_rate_m1 = (sweep_counter == sweep_rate - 16'd1);
    wire period_leq_end = (period <= end_period);
    wire period_geq_start = (period >= start_period);
    
    always @(posedge clk) begin
        if (rst) begin
            period <= start_period;
            counter <= 8'd0;
            sweep_counter <= 16'd0;
            sweep_dir <= 1'b0;
            sq_out <= 1'b0;
        end else begin
            // Counter for generating square wave - 优化比较逻辑
            if (counter_eq_period_m1) begin
                counter <= 8'd0;
                sq_out <= ~sq_out;
            end else begin
                counter <= counter + 8'd1;
            end
            
            // Counter for frequency sweep - 优化比较和分支逻辑
            if (sweep_counter_eq_rate_m1) begin
                sweep_counter <= 16'd0;
                
                // 简化条件分支，减少逻辑路径
                case (sweep_dir)
                    1'b0: begin // 频率增加模式
                        if (period_leq_end)
                            sweep_dir <= 1'b1;
                        else
                            period <= period - 8'd1;
                    end
                    1'b1: begin // 频率减少模式
                        if (period_geq_start)
                            sweep_dir <= 1'b0;
                        else
                            period <= period + 8'd1;
                    end
                endcase
            end else begin
                sweep_counter <= sweep_counter + 16'd1;
            end
        end
    end
endmodule