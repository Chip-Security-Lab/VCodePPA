//SystemVerilog
module freq_synthesizer(
    input ref_clk,
    input reset,
    input [1:0] mult_sel, // 00:x1, 01:x2, 10:x4, 11:x8
    output reg clk_out
);
    reg [1:0] counter;
    reg [3:0] phase_signals; // One-hot encoded phase signals: {phase_270, phase_180, phase_90, phase_0}
    
    // Optimized counter increment logic
    wire [1:0] next_counter = counter + 1'b1;
    
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            counter <= 2'b00;
            phase_signals <= 4'b0001; // Initially set phase_0 to 1
            clk_out <= 1'b0;
        end else begin
            counter <= next_counter;
            
            // Optimized phase signal generation using shift register concept
            phase_signals <= {phase_signals[2:0], phase_signals[3]};
            
            // Optimized clock output generation using efficient comparisons
            case (mult_sel)
                2'b00: clk_out <= phase_signals[0] & ~phase_signals[2]; // x1: phase_0 & ~phase_180
                2'b01: clk_out <= |{phase_signals[0], phase_signals[2]}; // x2: phase_0 | phase_180
                2'b10: clk_out <= |phase_signals; // x4: Any phase active
                2'b11: clk_out <= ~clk_out; // x8: Toggle on every cycle
            endcase
        end
    end
endmodule