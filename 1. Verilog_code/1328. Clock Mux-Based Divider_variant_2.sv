//SystemVerilog
module mux_divider (
    input main_clock, reset, enable,
    input [1:0] select,
    output out_clock
);
    // Internal signals
    wire [3:0] divider;
    
    // Sequential logic module instantiation
    divider_counter seq_logic (
        .main_clock(main_clock),
        .reset(reset),
        .enable(enable),
        .divider(divider)
    );
    
    // Combinational logic module instantiation
    divider_mux comb_logic (
        .divider(divider),
        .select(select),
        .out_clock(out_clock)
    );
endmodule

// Sequential logic module for the counter
module divider_counter (
    input main_clock,
    input reset,
    input enable,
    output reg [3:0] divider
);
    always @(posedge main_clock or posedge reset) begin
        if (reset)
            divider <= 4'b0000;
        else if (enable)
            divider <= divider + 1'b1;
        else
            divider <= divider; // Explicit hold state
    end
endmodule

// Combinational logic module for the multiplexer
module divider_mux (
    input [3:0] divider,
    input [1:0] select,
    output reg out_clock
);
    // Extract divided clock signals
    wire div2, div4, div8, div16;
    
    assign div2 = divider[0];
    assign div4 = divider[1];
    assign div8 = divider[2];
    assign div16 = divider[3];
    
    // Explicit multiplexer implementation
    always @(*) begin
        case (select)
            2'b00: out_clock = div2;
            2'b01: out_clock = div4;
            2'b10: out_clock = div8;
            2'b11: out_clock = div16;
            default: out_clock = div2; // Default case for completeness
        endcase
    end
endmodule