module freq_synthesizer(
    input ref_clk,
    input reset,
    input [1:0] mult_sel, // 00:x1, 01:x2, 10:x4, 11:x8
    output reg clk_out
);
    reg phase_0, phase_90, phase_180, phase_270;
    reg [1:0] counter;
    
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            counter <= 2'b00;
            phase_0 <= 1'b0;
            phase_90 <= 1'b0;
            phase_180 <= 1'b0;
            phase_270 <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            counter <= counter + 2'b01;
            
            case (counter)
                2'b00: phase_0 <= 1'b1;
                2'b01: phase_90 <= 1'b1;
                2'b10: phase_180 <= 1'b1;
                2'b11: phase_270 <= 1'b1;
            endcase
            
            case (mult_sel)
                2'b00: clk_out <= phase_0 & ~phase_180;
                2'b01: clk_out <= phase_0 | phase_180;
                2'b10: clk_out <= phase_0 | phase_90 | phase_180 | phase_270;
                2'b11: clk_out <= ~clk_out;
            endcase
        end
    end
endmodule