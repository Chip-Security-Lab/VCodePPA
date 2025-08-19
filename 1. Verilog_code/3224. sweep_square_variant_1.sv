//SystemVerilog
module sweep_square(
    input clk,
    input rst,
    input [7:0] start_period,
    input [7:0] end_period,
    input [15:0] sweep_rate,
    output reg sq_out
);
    // Combined stage for period calculation and square wave generation
    reg [7:0] period;
    reg [15:0] sweep_counter;
    reg sweep_dir;
    reg [7:0] counter;
    reg sq_state;
    
    always @(posedge clk) begin
        if (rst) begin
            period <= start_period;
            sweep_counter <= 16'd0;
            sweep_dir <= 1'b0;
            counter <= 8'd0;
            sq_state <= 1'b0;
            sq_out <= 1'b0;
        end else begin
            // Period calculation and sweep control
            if (sweep_counter >= sweep_rate-1) begin
                sweep_counter <= 16'd0;
                
                if (!sweep_dir) begin
                    if (period <= end_period) begin
                        sweep_dir <= 1'b1;
                    end else begin
                        period <= period - 8'd1;
                    end
                end else begin
                    if (period >= start_period) begin
                        sweep_dir <= 1'b0;
                    end else begin
                        period <= period + 8'd1;
                    end
                end
            end else begin
                sweep_counter <= sweep_counter + 16'd1;
            end
            
            // Square wave generation
            if (counter >= period-1) begin
                counter <= 8'd0;
                sq_state <= ~sq_state;
            end else begin
                counter <= counter + 8'd1;
            end
            
            // Output generation (single stage delay)
            sq_out <= sq_state;
        end
    end
endmodule