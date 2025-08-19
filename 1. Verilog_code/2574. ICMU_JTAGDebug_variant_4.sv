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
    reg [2:0] tap_state;
    reg [2:0] tap_state_buf;
    
    // LUT for state transitions
    reg [2:0] next_state_lut [0:7];
    initial begin
        next_state_lut[3'h0] = tms ? 3'h0 : 3'h1;  // IDLE -> DRSHIFT or stay
        next_state_lut[3'h1] = tms ? 3'h4 : 3'h1;  // DRSHIFT -> Exit or stay
        next_state_lut[3'h4] = 3'h0;               // Exit -> IDLE
        next_state_lut[3'h2] = 3'h0;               // Default transitions
        next_state_lut[3'h3] = 3'h0;
        next_state_lut[3'h5] = 3'h0;
        next_state_lut[3'h6] = 3'h0;
        next_state_lut[3'h7] = 3'h0;
    end

    // LUT for shift operations
    reg [DW-1:0] shift_op_lut [0:7];
    initial begin
        shift_op_lut[3'h0] = shift_reg_buf;        // IDLE: no shift
        shift_op_lut[3'h1] = {tdi, shift_reg_buf[DW-1:1]}; // DRSHIFT: shift in
        shift_op_lut[3'h4] = shift_reg_buf;        // Exit: no shift
        shift_op_lut[3'h2] = shift_reg_buf;        // Default: no shift
        shift_op_lut[3'h3] = shift_reg_buf;
        shift_op_lut[3'h5] = shift_reg_buf;
        shift_op_lut[3'h6] = shift_reg_buf;
        shift_op_lut[3'h7] = shift_reg_buf;
    end

    always @(posedge tck) begin
        tap_state <= next_state_lut[tap_state_buf];
        shift_reg <= shift_op_lut[tap_state_buf];
        
        if (tap_state_buf == 3'h4) begin
            debug_out <= shift_reg_buf;
        end
    end

    always @(posedge tck) begin
        shift_reg_buf <= shift_reg;
        tap_state_buf <= tap_state;
    end

    assign tdo = shift_reg_buf[0];
endmodule