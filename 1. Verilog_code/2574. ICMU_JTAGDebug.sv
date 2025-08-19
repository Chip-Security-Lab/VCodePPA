module ICMU_JTAGDebug #(
    parameter DW = 32
)(
    input tck,
    input tms,
    input tdi,
    output tdo,
    input [DW-1:0] ctx_data,
    output reg [DW-1:0] debug_out
);
    reg [DW-1:0] shift_reg;
    reg [2:0] tap_state;

    always @(posedge tck) begin
        case(tap_state)
            3'h0: if (!tms) tap_state <= 3'h1; // IDLE -> DRSHIFT
            3'h1: begin
                shift_reg <= {tdi, shift_reg[DW-1:1]};
                if (tms) tap_state <= 3'h4; // Exit
            end
            3'h4: begin
                debug_out <= shift_reg;
                tap_state <= 3'h0;
            end
            default: tap_state <= 3'h0;
        endcase
    end

    assign tdo = shift_reg[0];
endmodule
