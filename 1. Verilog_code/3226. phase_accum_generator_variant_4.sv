//SystemVerilog
module phase_accum_generator(
    input clock,
    input reset_n,
    input [11:0] phase_increment,
    input [1:0] waveform_select,
    output reg [7:0] wave_out
);
    reg [11:0] phase_accumulator;
    reg [11:0] phase_accumulator_saw;
    reg [11:0] phase_accumulator_tri;
    reg [11:0] phase_accumulator_sq;
    reg [11:0] phase_accumulator_pulse;
    
    // Main phase accumulator
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            phase_accumulator <= 12'd0;
        else
            phase_accumulator <= phase_accumulator + phase_increment;
    end
    
    // Buffered phase accumulators for different waveforms
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            phase_accumulator_saw <= 12'd0;
            phase_accumulator_tri <= 12'd0;
            phase_accumulator_sq <= 12'd0;
            phase_accumulator_pulse <= 12'd0;
        end
        else begin
            phase_accumulator_saw <= phase_accumulator;
            phase_accumulator_tri <= phase_accumulator;
            phase_accumulator_sq <= phase_accumulator;
            phase_accumulator_pulse <= phase_accumulator;
        end
    end
    
    // Output waveform generation with buffered signals
    always @(posedge clock) begin
        case (waveform_select)
            2'b00: // Sawtooth
                wave_out <= phase_accumulator_saw[11:4];
            2'b01: // Triangle
                wave_out <= phase_accumulator_tri[11] ? ~phase_accumulator_tri[10:3] : phase_accumulator_tri[10:3];
            2'b10: // Square
                wave_out <= phase_accumulator_sq[11] ? 8'd255 : 8'd0;
            2'b11: // Pulse
                wave_out <= (phase_accumulator_pulse[11:8] < 4'd4) ? 8'd255 : 8'd0;
        endcase
    end
endmodule