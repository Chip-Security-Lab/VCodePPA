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
    
    always @(posedge clk) begin
        if (rst) begin
            period <= start_period;
            counter <= 8'd0;
            sweep_counter <= 16'd0;
            sweep_dir <= 1'b0;
            sq_out <= 1'b0;
        end else begin
            // Counter for generating square wave
            if (counter >= period-1) begin
                counter <= 8'd0;
                sq_out <= ~sq_out;
            end else begin
                counter <= counter + 8'd1;
            end
            
            // Counter for frequency sweep
            if (sweep_counter >= sweep_rate-1) begin
                sweep_counter <= 16'd0;
                
                if (!sweep_dir) begin
                    if (period <= end_period)
                        sweep_dir <= 1'b1;
                    else
                        period <= period - 8'd1;
                end else begin
                    if (period >= start_period)
                        sweep_dir <= 1'b0;
                    else
                        period <= period + 8'd1;
                end
            end else begin
                sweep_counter <= sweep_counter + 16'd1;
            end
        end
    end
endmodule