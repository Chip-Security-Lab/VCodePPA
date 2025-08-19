//SystemVerilog
// Top-level module: Hierarchical binary to BCD converter using barrel shifter
module bin_to_bcd #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3  // Number of output BCD digits
)(
    input  wire [BIN_WIDTH-1:0]          binary_in,
    output wire [DIGITS*4-1:0]           bcd_out
);

    // Internal signal: extended temp register for shift/add-3 algorithm
    wire [BIN_WIDTH+DIGITS*4-1:0]        shift_add3_temp;

    // Internal signal: after initialization
    wire [BIN_WIDTH+DIGITS*4-1:0]        temp_init;

    // Initialization submodule
    bin_to_bcd_init #(
        .BIN_WIDTH(BIN_WIDTH),
        .DIGITS(DIGITS)
    ) u_init (
        .binary_in(binary_in),
        .temp_init(temp_init)
    );

    // Shift/Add-3 core submodule
    bin_to_bcd_shift_add3 #(
        .BIN_WIDTH(BIN_WIDTH),
        .DIGITS(DIGITS)
    ) u_shift_add3 (
        .temp_init(temp_init),
        .temp_shifted(shift_add3_temp)
    );

    // Output extraction submodule
    bin_to_bcd_output #(
        .BIN_WIDTH(BIN_WIDTH),
        .DIGITS(DIGITS)
    ) u_output (
        .temp_shifted(shift_add3_temp),
        .bcd_out(bcd_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: bin_to_bcd_init
// Initializes the temporary register for the shift/add-3 algorithm
//-----------------------------------------------------------------------------
module bin_to_bcd_init #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  wire [BIN_WIDTH-1:0]              binary_in,
    output wire [BIN_WIDTH+DIGITS*4-1:0]     temp_init
);
    assign temp_init = { {(DIGITS*4){1'b0}}, binary_in };
endmodule

//-----------------------------------------------------------------------------
// Barrel Shifter Module
//-----------------------------------------------------------------------------
module barrel_shifter_left #(
    parameter WIDTH = 20,
    parameter SHIFT_WIDTH = 8
)(
    input  wire [WIDTH-1:0]      data_in,
    input  wire [SHIFT_WIDTH-1:0] shift_amt,
    output wire [WIDTH-1:0]      data_out
);
    wire [WIDTH-1:0] stage [0:SHIFT_WIDTH];

    assign stage[0] = data_in;

    genvar k;
    generate
        for (k = 0; k < SHIFT_WIDTH; k = k + 1) begin : gen_barrel
            assign stage[k+1] = shift_amt[k] ? (stage[k] << (1 << k)) : stage[k];
        end
    endgenerate

    assign data_out = stage[SHIFT_WIDTH];
endmodule

//-----------------------------------------------------------------------------
// Submodule: bin_to_bcd_shift_add3
// Implements the shift/add-3 algorithm using a barrel shifter
//-----------------------------------------------------------------------------
module bin_to_bcd_shift_add3 #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  wire [BIN_WIDTH+DIGITS*4-1:0]     temp_init,
    output reg  [BIN_WIDTH+DIGITS*4-1:0]     temp_shifted
);

    localparam TOTAL_WIDTH = BIN_WIDTH + DIGITS*4;
    localparam SHIFT_WIDTH = $clog2(BIN_WIDTH+1);

    integer i, j;
    reg [TOTAL_WIDTH-1:0] temp;
    wire [TOTAL_WIDTH-1:0] barrel_out [0:BIN_WIDTH];

    // Use intermediate wires for each stage to allow synthesis-friendly mapping
    assign barrel_out[0] = temp_init;

    generate
        genvar stage;
        for (stage = 0; stage < BIN_WIDTH; stage = stage + 1) begin : gen_shift_add3
            reg [TOTAL_WIDTH-1:0] temp_stage;
            integer d;
            always @(*) begin
                temp_stage = barrel_out[stage];
                for (d = 0; d < DIGITS; d = d + 1) begin
                    if (temp_stage[BIN_WIDTH+d*4 +: 4] > 4'd4)
                        temp_stage[BIN_WIDTH+d*4 +: 4] = temp_stage[BIN_WIDTH+d*4 +: 4] + 4'd3;
                end
            end

            // Barrel shift by 1 at each stage
            barrel_shifter_left #(
                .WIDTH(TOTAL_WIDTH),
                .SHIFT_WIDTH(1)
            ) u_barrel (
                .data_in(temp_stage),
                .shift_amt(1'b1),
                .data_out(barrel_out[stage+1])
            );
        end
    endgenerate

    always @(*) begin
        temp_shifted = barrel_out[BIN_WIDTH];
    end

endmodule

//-----------------------------------------------------------------------------
// Submodule: bin_to_bcd_output
// Extracts the BCD result from the shifted temp register
//-----------------------------------------------------------------------------
module bin_to_bcd_output #(
    parameter BIN_WIDTH = 8,
    parameter DIGITS = 3
)(
    input  wire [BIN_WIDTH+DIGITS*4-1:0]     temp_shifted,
    output wire [DIGITS*4-1:0]               bcd_out
);
    assign bcd_out = temp_shifted[BIN_WIDTH+DIGITS*4-1:BIN_WIDTH];
endmodule