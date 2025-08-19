//SystemVerilog
module CaseMux #(parameter N=4, DW=8) (
    input  wire [$clog2(N)-1:0] sel,
    input  wire [N*DW-1:0]      din_flat,
    output wire [DW-1:0]        dout
);

    // Internal signals
    wire [DW-1:0] din_selected;
    wire [DW-1:0] subtrahend_const;
    wire [DW-1:0] difference;
    wire          borrow_out;

    // Unpack din_flat to din_array for easier indexing
    wire [DW-1:0] din_array [0:N-1];
    genvar idx;
    generate
        for (idx = 0; idx < N; idx = idx + 1) begin : UNPACK_DIN
            assign din_array[idx] = din_flat[DW*idx +: DW];
        end
    endgenerate

    // din_selected: combinational always block for multiplexer
    reg [DW-1:0] din_selected_reg;
    always @(*) begin
        din_selected_reg = din_array[sel];
    end
    assign din_selected = din_selected_reg;

    // Subtrahend constant assignment
    assign subtrahend_const = 8'd42;

    // BorrowSubtractor8 instantiation
    BorrowSubtractor8 u_borrow_subtractor8 (
        .minuend    (din_selected),
        .subtrahend (subtrahend_const),
        .difference (difference),
        .borrow_out (borrow_out)
    );

    // Output assignment
    assign dout = difference;

endmodule

module BorrowSubtractor8 (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] difference,
    output wire       borrow_out
);

    // Internal signals for borrow and difference
    reg [7:0] borrow_internal;
    reg [7:0] diff_internal;

    // Bit 0 subtraction
    always @(*) begin
        {borrow_internal[0], diff_internal[0]} = {1'b0, minuend[0]} - {1'b0, subtrahend[0]};
    end

    // Bits 1-7 subtraction
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : SUB_BITS
            always @(*) begin
                {borrow_internal[i], diff_internal[i]} = {borrow_internal[i-1], minuend[i]} - {1'b0, subtrahend[i]} - borrow_internal[i-1];
            end
        end
    endgenerate

    // Output assignments
    assign difference = diff_internal;
    assign borrow_out = borrow_internal[7];

endmodule