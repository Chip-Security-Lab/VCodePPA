module chirp_generator(
    input clk,
    input rst,
    input [15:0] start_freq,
    input [15:0] freq_step,
    input [7:0] step_interval,
    output reg [7:0] chirp_out
);
    reg [15:0] freq;
    reg [15:0] phase_acc;
    reg [7:0] interval_counter;
    
    always @(posedge clk) begin
        if (rst) begin
            freq <= start_freq;
            phase_acc <= 16'd0;
            interval_counter <= 8'd0;
            chirp_out <= 8'd128;
        end else begin
            // Phase accumulation based on current frequency
            phase_acc <= phase_acc + freq;
            
            // Simple sine approximation using MSBs
            if (phase_acc[15:14] == 2'b00)
                chirp_out <= 8'd128 + {1'b0, phase_acc[13:7]};
            else if (phase_acc[15:14] == 2'b01)
                chirp_out <= 8'd255 - {1'b0, phase_acc[13:7]};
            else if (phase_acc[15:14] == 2'b10)
                chirp_out <= 8'd127 - {1'b0, phase_acc[13:7]};
            else
                chirp_out <= 8'd0 + {1'b0, phase_acc[13:7]};
                
            // Frequency stepping logic
            if (interval_counter >= step_interval) begin
                interval_counter <= 8'd0;
                freq <= freq + freq_step;
            end else begin
                interval_counter <= interval_counter + 8'd1;
            end
        end
    end
endmodule