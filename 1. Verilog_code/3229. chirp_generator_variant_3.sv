//SystemVerilog
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
    
    // Buffer registers for high fanout signals
    reg [15:0] phase_acc_buf1, phase_acc_buf2;
    reg [1:0] phase_msb_buf;
    reg [6:0] phase_lsb_buf;
    
    // Additional computed values with buffer registers
    reg [7:0] d0, d0_buf1, d0_buf2;
    reg [7:0] b0, b0_buf1, b0_buf2;
    
    always @(posedge clk) begin
        if (rst) begin
            freq <= start_freq;
            phase_acc <= 16'd0;
            interval_counter <= 8'd0;
            chirp_out <= 8'd128;
            
            // Reset buffers
            phase_acc_buf1 <= 16'd0;
            phase_acc_buf2 <= 16'd0;
            phase_msb_buf <= 2'b00;
            phase_lsb_buf <= 7'd0;
            d0 <= 8'd128;
            d0_buf1 <= 8'd128;
            d0_buf2 <= 8'd128;
            b0 <= 8'd0;
            b0_buf1 <= 8'd0;
            b0_buf2 <= 8'd0;
        end else begin
            // Phase accumulation based on current frequency
            phase_acc <= phase_acc + freq;
            
            // Buffer the high fanout phase accumulator
            phase_acc_buf1 <= phase_acc;
            phase_acc_buf2 <= phase_acc_buf1;
            
            // Split and buffer critical phase bits to reduce fanout
            phase_msb_buf <= phase_acc_buf1[15:14];
            phase_lsb_buf <= phase_acc_buf1[13:7];
            
            // Pre-compute common values with buffering
            d0 <= 8'd128 + {1'b0, phase_lsb_buf};
            d0_buf1 <= d0;
            d0_buf2 <= d0_buf1;
            
            b0 <= {1'b0, phase_lsb_buf};
            b0_buf1 <= b0;
            b0_buf2 <= b0_buf1;
            
            // Simple sine approximation using buffered values
            case(phase_msb_buf)
                2'b00: chirp_out <= d0_buf2;
                2'b01: chirp_out <= 8'd255 - b0_buf2;
                2'b10: chirp_out <= 8'd127 - b0_buf2;
                2'b11: chirp_out <= b0_buf2;
            endcase
                
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