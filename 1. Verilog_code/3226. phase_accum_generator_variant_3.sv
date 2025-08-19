//SystemVerilog
module phase_accum_generator(
    input clock,
    input reset_n,
    input [11:0] phase_increment,
    input [1:0] waveform_select,
    output reg [7:0] wave_out
);
    reg [11:0] phase_accumulator;
    reg [11:0] phase_buf1, phase_buf2;
    
    // Main phase accumulator logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            phase_accumulator <= 12'd0;
        else
            phase_accumulator <= phase_accumulator + phase_increment;
    end
    
    // Buffer registers for high fan-out phase_accumulator signal
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            phase_buf1 <= 12'd0;
            phase_buf2 <= 12'd0;
        end
        else begin
            phase_buf1 <= phase_accumulator;
            phase_buf2 <= phase_accumulator;
        end
    end
    
    // Waveform generation using buffered signals
    always @(posedge clock) begin
        case (waveform_select)
            2'b00: // Sawtooth
                wave_out <= phase_buf1[11:4];
            2'b01: begin // Triangle
                if (phase_buf1[11]) 
                    wave_out <= ~phase_buf1[10:3];
                else
                    wave_out <= phase_buf1[10:3];
            end
            2'b10: begin // Square
                if (phase_buf2[11]) 
                    wave_out <= 8'd255;
                else
                    wave_out <= 8'd0;
            end
            2'b11: begin // Pulse
                if (phase_buf2[11:8] < 4'd4) 
                    wave_out <= 8'd255;
                else
                    wave_out <= 8'd0;
            end
        endcase
    end
endmodule