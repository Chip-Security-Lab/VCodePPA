//SystemVerilog
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
    // Signals for parallel prefix subtractor
    reg [PHASE_WIDTH-1:0] phase_acc;
    wire [PHASE_WIDTH-1:0] next_phase_acc;
    wire [PHASE_WIDTH-1:0] subtractor_result;
    
    // Generate and propagate signals for 2-bit parallel prefix subtractor
    wire [1:0] g, p;
    wire c_out;
    
    // Parallel prefix subtractor implementation (2-bit)
    parallel_prefix_subtractor_2bit subtractor (
        .a(phase_acc[1:0]),
        .b(~freq_word[1:0]),
        .c_in(1'b1),
        .diff(subtractor_result[1:0]),
        .c_out(c_out)
    );
    
    // Sine LUT
    reg [OUT_WIDTH-1:0] sin_lut [0:15]; // 16-entry sine LUT
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd176; sin_lut[2] = 8'd218; sin_lut[3] = 8'd245;
        sin_lut[4] = 8'd255; sin_lut[5] = 8'd245; sin_lut[6] = 8'd218; sin_lut[7] = 8'd176;
        sin_lut[8] = 8'd128; sin_lut[9] = 8'd79;  sin_lut[10] = 8'd37; sin_lut[11] = 8'd10;
        sin_lut[12] = 8'd0;  sin_lut[13] = 8'd10; sin_lut[14] = 8'd37; sin_lut[15] = 8'd79;
    end
    
    // Calculate next phase accumulator value using explicit multiplexer
    // Use subtractor for lower 2 bits and regular addition for higher bits
    wire carry_mux_sel;
    wire [PHASE_WIDTH-3:0] carry_mux_out;
    
    assign carry_mux_sel = c_out;
    assign carry_mux_out = carry_mux_sel ? {(PHASE_WIDTH-2){1'b0}} : {{(PHASE_WIDTH-3){1'b0}}, 1'b1};
    assign next_phase_acc = {phase_acc[PHASE_WIDTH-1:2] + freq_word[PHASE_WIDTH-1:2] + carry_mux_out, subtractor_result[1:0]};
    
    // Triangle wave calculation using explicit multiplexer
    wire [OUT_WIDTH-1:0] triangle_wave;
    wire triangle_sel;
    wire [OUT_WIDTH-1:0] triangle_mux_in0, triangle_mux_in1;
    
    assign triangle_sel = phase_acc[PHASE_WIDTH-1];
    assign triangle_mux_in0 = phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1];
    assign triangle_mux_in1 = ~phase_acc[PHASE_WIDTH-2:PHASE_WIDTH-OUT_WIDTH-1];
    assign triangle_wave = triangle_sel ? triangle_mux_in1 : triangle_mux_in0;
    
    // Square wave calculation using explicit multiplexer
    wire [OUT_WIDTH-1:0] square_wave;
    wire square_sel;
    wire [OUT_WIDTH-1:0] square_mux_in0, square_mux_in1;
    
    assign square_sel = phase_acc[PHASE_WIDTH-1];
    assign square_mux_in0 = {OUT_WIDTH{1'b0}};
    assign square_mux_in1 = {OUT_WIDTH{1'b1}};
    assign square_wave = square_sel ? square_mux_in1 : square_mux_in0;
    
    // Sine wave calculation
    wire [OUT_WIDTH-1:0] sine_wave;
    assign sine_wave = sin_lut[phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-4]];
    
    // Sawtooth wave calculation
    wire [OUT_WIDTH-1:0] sawtooth_wave;
    assign sawtooth_wave = phase_acc[PHASE_WIDTH-1:PHASE_WIDTH-OUT_WIDTH];
    
    // Output wave selection multiplexer
    wire [OUT_WIDTH-1:0] wave_mux_out [0:3];
    assign wave_mux_out[0] = sine_wave;
    assign wave_mux_out[1] = triangle_wave;
    assign wave_mux_out[2] = sawtooth_wave;
    assign wave_mux_out[3] = square_wave;
    
    always @(posedge clk) begin
        if (reset)
            phase_acc <= {PHASE_WIDTH{1'b0}};
        else
            phase_acc <= phase_acc + freq_word;
            
        dds_out <= wave_mux_out[wave_sel];
    end
endmodule

module parallel_prefix_subtractor_2bit (
    input [1:0] a,      // Minuend
    input [1:0] b,      // Subtrahend (already negated for subtraction)
    input c_in,         // Carry-in (set to 1 for subtraction)
    output [1:0] diff,  // Result
    output c_out        // Carry-out
);
    // Generate and propagate signals
    wire [1:0] g, p;
    wire [2:0] c; // c[0] is c_in, c[2] is c_out
    
    // Step 1: Generate the generate and propagate signals
    assign g[0] = a[0] & b[0];
    assign p[0] = a[0] ^ b[0];
    assign g[1] = a[1] & b[1];
    assign p[1] = a[1] ^ b[1];
    
    // Step 2: Calculate carries using prefix structure
    assign c[0] = c_in;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    
    // Step 3: Calculate differences
    assign diff[0] = p[0] ^ c[0];
    assign diff[1] = p[1] ^ c[1];
    
    // Carry-out
    assign c_out = c[2];
endmodule