//SystemVerilog
module Par2SerMux #(parameter DW=8) (
    input wire clk,
    input wire load,
    input wire [DW-1:0] par_in,
    output wire ser_out
);

    wire [DW-1:0] shift_next_comb;
    reg  [DW-1:0] shift_reg;
    wire ser_out_comb;

    // Combinational logic for next shift value
    Par2SerMux_comb #(.DW(DW)) u_comb (
        .load(load),
        .par_in(par_in),
        .shift_reg_curr(shift_reg),
        .shift_next(shift_next_comb),
        .ser_out(ser_out_comb)
    );

    // Sequential logic for shift register
    always @(posedge clk) begin
        shift_reg <= shift_next_comb;
    end

    assign ser_out = ser_out_comb;

endmodule

module Par2SerMux_comb #(parameter DW=8) (
    input wire load,
    input wire [DW-1:0] par_in,
    input wire [DW-1:0] shift_reg_curr,
    output wire [DW-1:0] shift_next,
    output wire ser_out
);

    // Combinational logic for next shift value
    assign shift_next = load ? par_in : (shift_reg_curr >> 1);

    // Combinational logic for serial output
    assign ser_out = shift_reg_curr[0];

endmodule