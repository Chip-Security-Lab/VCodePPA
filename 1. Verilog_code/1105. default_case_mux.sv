module default_case_mux (
    input wire [2:0] channel_sel, // Channel selector
    input wire [15:0] ch0, ch1, ch2, ch3, ch4, // Channel data
    output reg [15:0] selected    // Selected output
);
    always @(*) begin
        case(channel_sel)
            3'b000: selected = ch0;
            3'b001: selected = ch1;
            3'b010: selected = ch2;
            3'b011: selected = ch3;
            3'b100: selected = ch4;
            default: selected = 16'h0000; // Default for undefined states
        endcase
    end
endmodule