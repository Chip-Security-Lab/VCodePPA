//SystemVerilog
`timescale 1ns / 1ps
module freq_synthesizer(
    input ref_clk,
    input reset,
    input [1:0] mult_sel, // 00:x1, 01:x2, 10:x4, 11:x8
    output reg clk_out
);
    // Main counter
    reg [1:0] counter;
    
    // Buffered counter signals to distribute load
    reg [1:0] counter_buf1, counter_buf2;
    
    // Phase signals
    wire phase_0, phase_90, phase_180, phase_270;
    
    // Buffered phase signals for high fan-out
    reg phase_0_buf1, phase_0_buf2;
    reg phase_180_buf1, phase_180_buf2;
    
    // Output clock next state
    reg clk_out_next;
    
    // Buffered version of next clock output
    reg clk_out_next_buf;
    
    // Phase detection logic split into multiple paths to reduce load
    assign phase_0 = (counter == 2'b00);
    assign phase_90 = (counter_buf1 == 2'b01);
    assign phase_180 = (counter == 2'b10);
    assign phase_270 = (counter_buf2 == 2'b11);
    
    // Generate next clock output value combinationally
    always @(*) begin
        case (mult_sel)
            2'b00: clk_out_next = phase_0_buf1 & ~phase_180_buf1;
            2'b01: clk_out_next = phase_0_buf2 | phase_180_buf2;
            2'b10: clk_out_next = phase_0 | phase_90 | phase_180 | phase_270;
            2'b11: clk_out_next = ~clk_out;
            default: clk_out_next = clk_out;
        endcase
    end
    
    // Single clock domain register update with buffer registers
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            counter <= 2'b00;
            counter_buf1 <= 2'b00;
            counter_buf2 <= 2'b00;
            phase_0_buf1 <= 1'b1;
            phase_0_buf2 <= 1'b1;
            phase_180_buf1 <= 1'b0;
            phase_180_buf2 <= 1'b0;
            clk_out_next_buf <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            counter <= counter + 2'b01;
            counter_buf1 <= counter;
            counter_buf2 <= counter;
            
            // Buffer the high fan-out phase signals
            phase_0_buf1 <= phase_0;
            phase_0_buf2 <= phase_0;
            phase_180_buf1 <= phase_180;
            phase_180_buf2 <= phase_180;
            
            // Buffer the clock output next value
            clk_out_next_buf <= clk_out_next;
            clk_out <= clk_out_next_buf;
        end
    end
endmodule