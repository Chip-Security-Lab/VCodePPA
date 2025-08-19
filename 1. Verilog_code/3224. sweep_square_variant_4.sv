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
    
    // Counter for generating square wave - optimized comparison
    always @(posedge clk) begin
        if (rst) begin
            counter <= 8'd0;
            sq_out <= 1'b0;
        end else begin
            counter <= (counter == period-1) ? 8'd0 : counter + 8'd1;
            if (counter == period-1)
                sq_out <= ~sq_out;
        end
    end
    
    // Counter for sweep timing - optimized with equality check
    always @(posedge clk) begin
        if (rst) begin
            sweep_counter <= 16'd0;
        end else begin
            sweep_counter <= (sweep_counter == sweep_rate-1) ? 16'd0 : sweep_counter + 16'd1;
        end
    end
    
    // Period control logic - optimized comparisons
    always @(posedge clk) begin
        if (rst) begin
            period <= start_period;
            sweep_dir <= 1'b0;
        end else if (sweep_counter == sweep_rate-1) begin
            case (sweep_dir)
                1'b0: begin // Increasing frequency (decreasing period)
                    if (period <= end_period + 8'd1) begin
                        sweep_dir <= 1'b1;
                        period <= end_period;
                    end else begin
                        period <= period - 8'd1;
                    end
                end
                1'b1: begin // Decreasing frequency (increasing period)
                    if (period >= start_period - 8'd1) begin
                        sweep_dir <= 1'b0;
                        period <= start_period;
                    end else begin
                        period <= period + 8'd1;
                    end
                end
            endcase
        end
    end
endmodule