//SystemVerilog
// Top level module
module mux_d_latch (
    input wire [3:0] d_inputs,
    input wire [1:0] select, 
    input wire enable,
    output wire q
);

    // Internal signals
    wire mux_out;
    
    // Instantiate submodules
    mux_4to1 mux_inst (
        .d_inputs(d_inputs),
        .select(select),
        .out(mux_out)
    );
    
    d_latch latch_inst (
        .d(mux_out),
        .enable(enable),
        .q(q)
    );

endmodule

// 4-to-1 multiplexer submodule
module mux_4to1 (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    output reg out
);
    always @* begin
        case(select)
            2'b00: out = d_inputs[0];
            2'b01: out = d_inputs[1];
            2'b10: out = d_inputs[2];
            2'b11: out = d_inputs[3];
            default: out = 1'b0;
        endcase
    end
endmodule

// D-latch submodule
module d_latch (
    input wire d,
    input wire enable,
    output reg q
);
    always @* begin
        if (enable) begin
            q = d;
        end
        // else q retains its previous value
    end
endmodule