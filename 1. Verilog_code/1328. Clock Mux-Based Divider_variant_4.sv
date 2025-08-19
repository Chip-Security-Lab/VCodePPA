//SystemVerilog - IEEE 1364-2005 standard

// Top-level module
module mux_divider (
    input main_clock, reset, enable,
    input [1:0] select,
    output reg out_clock
);
    wire div2, div4, div8, div16;
    
    // Clock divider submodule instantiation
    clock_divider divider_inst (
        .main_clock(main_clock),
        .reset(reset),
        .enable(enable),
        .div2(div2),
        .div4(div4),
        .div8(div8),
        .div16(div16)
    );
    
    // Clock multiplexer submodule instantiation
    clock_multiplexer mux_inst (
        .select(select),
        .div2(div2),
        .div4(div4),
        .div8(div8),
        .div16(div16),
        .out_clock(out_clock)
    );
endmodule

// Clock divider submodule
module clock_divider (
    input main_clock, reset, enable,
    output div2, div4, div8, div16
);
    reg [3:0] divider;
    
    // Counter logic
    always @(posedge main_clock or posedge reset) begin
        if (reset)
            divider <= 4'b0000;
        else if (enable)
            divider <= divider + 1'b1;
    end
    
    // Frequency division outputs
    assign div2 = divider[0];
    assign div4 = divider[1];
    assign div8 = divider[2];
    assign div16 = divider[3];
endmodule

// Clock multiplexer submodule
module clock_multiplexer (
    input [1:0] select,
    input div2, div4, div8, div16,
    output reg out_clock
);
    // Clock selection logic
    always @(*) begin
        case (select)
            2'b00: out_clock = div2;
            2'b01: out_clock = div4;
            2'b10: out_clock = div8;
            2'b11: out_clock = div16;
        endcase
    end
endmodule