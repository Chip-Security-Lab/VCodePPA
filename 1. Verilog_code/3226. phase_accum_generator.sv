module phase_accum_generator(
    input clock,
    input reset_n,
    input [11:0] phase_increment,
    input [1:0] waveform_select,
    output reg [7:0] wave_out
);
    reg [11:0] phase_accumulator;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            phase_accumulator <= 12'd0;
        else
            phase_accumulator <= phase_accumulator + phase_increment;
    end
    
    always @(posedge clock) begin
        case (waveform_select)
            2'b00: // Sawtooth
                wave_out <= phase_accumulator[11:4];
            2'b01: // Triangle
                wave_out <= phase_accumulator[11] ? ~phase_accumulator[10:3] : phase_accumulator[10:3];
            2'b10: // Square
                wave_out <= phase_accumulator[11] ? 8'd255 : 8'd0;
            2'b11: // Pulse
                wave_out <= (phase_accumulator[11:8] < 4'd4) ? 8'd255 : 8'd0;
        endcase
    end
endmodule