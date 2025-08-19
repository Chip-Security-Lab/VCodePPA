//SystemVerilog
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
    reg [DW-1:0] shift_reg_buf;
    reg [3:0] tap_state;  // Changed to 4 bits for one-hot encoding
    reg [3:0] tap_state_buf;

    // One-hot state definitions
    localparam IDLE    = 4'b0001;
    localparam DRSHIFT = 4'b0010;
    localparam EXIT    = 4'b1000;

    always @(posedge tck) begin
        case(tap_state_buf)
            IDLE: if (!tms) tap_state <= DRSHIFT;
            DRSHIFT: begin
                shift_reg <= {tdi, shift_reg_buf[DW-1:1]};
                if (tms) tap_state <= EXIT;
            end
            EXIT: begin
                debug_out <= shift_reg_buf;
                tap_state <= IDLE;
            end
            default: tap_state <= IDLE;
        endcase
    end

    always @(posedge tck) begin
        shift_reg_buf <= shift_reg;
        tap_state_buf <= tap_state;
    end

    assign tdo = shift_reg_buf[0];
endmodule