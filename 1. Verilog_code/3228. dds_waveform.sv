module dds_waveform #(
    parameter PHASE_WIDTH = 12,
    parameter OUT_WIDTH = 8
)(
    input clk,
    input reset,
    input [PHASE_WIDTH-1:0] freq_word,
    input [1:0] wave_sel,
    output reg [OUT_WIDTH-1:0] dds_out
);
    reg [PHASE_WIDTH-1:0] phase_acc;
    reg [OUT_WIDTH-1:0] sin_lut [0:15]; // 16-entry sine LUT
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd176; sin_lut[2] = 8'd218; sin_lut[3] = 8'd245;
        sin_lut[4] = 8'd255; sin_lut[5] = 8'd245; sin_lut[6] = 8'd218; sin_lut[7] = 8'd176;
        sin_lut[8] = 8'd128; sin_lut[9] = 8'd79;  sin_lut[10] = 8'd37; sin_lut[11] = 8'd10;
        sin_lut[12] = 8'd0;  sin_lut[13] = 8'd10; sin_lut[14] = 8'd37; sin_lut[15] = 8'd79;
    end
    
    always @(posedge clk) begin
        if (reset)
            phase_acc <= {PHASE_WIDTH{1'b0}};
        else
            phase_acc <= phase_acc + freq_word;
            
        case (wave_sel)
            2'b00: // Sine
                dds_out <= sin_lut[phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-4]];
            2'b01: // Triangle
                dds_out <= phase_acc[PHASE_WIDTH-1] ? ~phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1] : 
                                                      phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1];
            2'b10: // Sawtooth
                dds_out <= phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-OUT_WIDTH];
            2'b11: // Square
                dds_out <= phase_acc[PHASE_WIDTH-1] ? {OUT_WIDTH{1'b1}} : {OUT_WIDTH{1'b0}};
        endcase
    end
endmodule
