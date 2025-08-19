//SystemVerilog
// Top-Level Module: unsigned_to_signed
module unsigned_to_signed #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      unsigned_in,
    output wire [WIDTH-1:0]      signed_out,
    output wire                  overflow
);

    // =========================================================================
    // Internal Signals for Submodule Interconnection
    // =========================================================================
    wire [WIDTH-1:0]             unsigned_in_stage1;
    wire                         msb_stage2;
    wire [WIDTH-2:0]             lower_bits_stage2;
    wire [WIDTH-1:0]             signed_data_stage3;
    wire                         overflow_stage3;

    // =========================================================================
    // Stage 1: Input Latching
    // =========================================================================
    input_latch #(
        .WIDTH(WIDTH)
    ) u_input_latch (
        .clk           (clk),
        .rst_n         (rst_n),
        .unsigned_in   (unsigned_in),
        .latched_data  (unsigned_in_stage1)
    );

    // =========================================================================
    // Stage 2: MSB Extraction & Lower Bits
    // =========================================================================
    msb_extract #(
        .WIDTH(WIDTH)
    ) u_msb_extract (
        .clk           (clk),
        .rst_n         (rst_n),
        .data_in       (unsigned_in_stage1),
        .msb_out       (msb_stage2),
        .lower_bits    (lower_bits_stage2)
    );

    // =========================================================================
    // Stage 3: Data Path Decision & Overflow Calculation
    // =========================================================================
    signed_data_path #(
        .WIDTH(WIDTH)
    ) u_signed_data_path (
        .clk           (clk),
        .rst_n         (rst_n),
        .msb_in        (msb_stage2),
        .lower_bits_in (lower_bits_stage2),
        .signed_data   (signed_data_stage3),
        .overflow      (overflow_stage3)
    );

    // =========================================================================
    // Output Assignments
    // =========================================================================
    assign signed_out = signed_data_stage3;
    assign overflow   = overflow_stage3;

endmodule

// ============================================================================
// Submodule: input_latch
// Function: Latches the unsigned input on the rising edge of clk.
// ============================================================================
module input_latch #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [WIDTH-1:0]     unsigned_in,
    output reg  [WIDTH-1:0]     latched_data
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            latched_data <= {WIDTH{1'b0}};
        else
            latched_data <= unsigned_in;
    end
endmodule

// ============================================================================
// Submodule: msb_extract
// Function: Extracts MSB and lower bits from input data.
// ============================================================================
module msb_extract #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [WIDTH-1:0]     data_in,
    output reg                  msb_out,
    output reg  [WIDTH-2:0]     lower_bits
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            msb_out    <= 1'b0;
            lower_bits <= {(WIDTH-1){1'b0}};
        end else begin
            msb_out    <= data_in[WIDTH-1];
            lower_bits <= data_in[WIDTH-2:0];
        end
    end
endmodule

// ============================================================================
// Submodule: signed_data_path
// Function: Generates signed output and overflow flag based on MSB.
// ============================================================================
module signed_data_path #(
    parameter WIDTH = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 msb_in,
    input  wire [WIDTH-2:0]     lower_bits_in,
    output reg  [WIDTH-1:0]     signed_data,
    output reg                  overflow
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signed_data <= {WIDTH{1'b0}};
            overflow    <= 1'b0;
        end else begin
            overflow    <= msb_in;
            signed_data <= msb_in ? {1'b0, lower_bits_in} : {msb_in, lower_bits_in};
        end
    end
endmodule