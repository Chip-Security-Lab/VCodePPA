module configurable_clock_gate (
    input  wire clk_in,
    input  wire [1:0] mode,
    input  wire ctrl,
    output wire clk_out
);
    reg gate_signal;
    
    always @(*) begin
        case (mode)
            2'b00: gate_signal = ctrl;      // Direct mode
            2'b01: gate_signal = ~ctrl;     // Inverted mode
            2'b10: gate_signal = 1'b1;      // Always on
            2'b11: gate_signal = 1'b0;      // Always off
        endcase
    end
    
    assign clk_out = clk_in & gate_signal;
endmodule