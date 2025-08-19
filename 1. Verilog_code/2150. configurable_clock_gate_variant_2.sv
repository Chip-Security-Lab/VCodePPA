//SystemVerilog
module configurable_clock_gate (
    input  wire clk_in,
    input  wire [1:0] mode,
    input  wire ctrl,
    output wire clk_out
);
    reg gate_signal;
    
    // Simplified mode evaluation without Karatsuba multiplier
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

// Optimized direct 4-bit multiplier
module karatsuba_4bit_mult (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [7:0] y
);
    wire [3:0] p0, p1, p2, p3;
    
    // Generate partial products directly
    assign p0 = b[0] ? a : 4'b0000;
    assign p1 = b[1] ? a : 4'b0000;
    assign p2 = b[2] ? a : 4'b0000;
    assign p3 = b[3] ? a : 4'b0000;
    
    // Combine with appropriate shifts
    assign y = p0 + (p1 << 1) + (p2 << 2) + (p3 << 3);
endmodule

// Direct implementation of 2-bit multiplier
module karatsuba_2bit_mult (
    input  wire [1:0] a,
    input  wire [1:0] b,
    output wire [3:0] y
);
    wire [1:0] p0, p1;
    
    // Generate partial products directly
    assign p0 = b[0] ? a : 2'b00;
    assign p1 = b[1] ? a : 2'b00;
    
    // Combine with appropriate shift
    assign y = {2'b00, p0} + {p1, 1'b0};
endmodule