//SystemVerilog
// Top-level module: Bit-sliced RNG AXI Stream
module bit_sliced_rng_axi_stream (
    input  wire         clk,
    input  wire         rst_n,
    output wire [31:0]  m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);

    // Internal LFSR outputs
    wire [7:0] lfsr_slice0_out;
    wire [7:0] lfsr_slice1_out;
    wire [7:0] lfsr_slice2_out;
    wire [7:0] lfsr_slice3_out;

    // Internal AXI Stream signals
    wire        tvalid_out;
    wire        tlast_out;

    // LFSR Slices (Parameterizable, functionally identical except taps/init)
    lfsr8_slice #(
        .INIT_VALUE (8'h1),
        .TAP_MASK   (8'b10111000) // taps: [7] [5] [4] [3]
    ) u_lfsr_slice0 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (m_axis_tready),
        .lfsr_out   (lfsr_slice0_out)
    );

    lfsr8_slice #(
        .INIT_VALUE (8'h2),
        .TAP_MASK   (8'b11000011) // taps: [7] [6] [1] [0]
    ) u_lfsr_slice1 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (m_axis_tready),
        .lfsr_out   (lfsr_slice1_out)
    );

    lfsr8_slice #(
        .INIT_VALUE (8'h4),
        .TAP_MASK   (8'b11100001) // taps: [7] [6] [5] [0]
    ) u_lfsr_slice2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (m_axis_tready),
        .lfsr_out   (lfsr_slice2_out)
    );

    lfsr8_slice #(
        .INIT_VALUE (8'h8),
        .TAP_MASK   (8'b10001110) // taps: [7] [3] [2] [1]
    ) u_lfsr_slice3 (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (m_axis_tready),
        .lfsr_out   (lfsr_slice3_out)
    );

    // AXI Stream control logic
    axi_stream_ctrl u_axi_stream_ctrl (
        .clk             (clk),
        .rst_n           (rst_n),
        .tready          (m_axis_tready),
        .tvalid          (tvalid_out),
        .tlast           (tlast_out)
    );

    // Output assignments
    assign m_axis_tdata  = {lfsr_slice3_out, lfsr_slice2_out, lfsr_slice1_out, lfsr_slice0_out};
    assign m_axis_tvalid = tvalid_out;
    assign m_axis_tlast  = tlast_out;

endmodule

//-----------------------------------------------------------------------------

// 8-bit LFSR Slice Module (parameterized taps and initial value)
// TAP_MASK: bit position 1 for tap, 0 for no tap. [7:0] corresponds to lfsr[7:0]
module lfsr8_slice #(
    parameter [7:0] INIT_VALUE = 8'h1,
    parameter [7:0] TAP_MASK   = 8'b00000000
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       enable,
    output reg [7:0]  lfsr_out
);
    // Compute feedback bit based on TAP_MASK
    wire feedback;
    assign feedback = ^(lfsr_out & TAP_MASK);

    // Sequential LFSR update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_out <= INIT_VALUE;
        end else if (enable) begin
            lfsr_out <= {lfsr_out[6:0], feedback};
        end
    end
endmodule

//-----------------------------------------------------------------------------

// AXI Stream Control Logic Module
// Generates tvalid and tlast signals for continuous streaming
module axi_stream_ctrl (
    input  wire clk,
    input  wire rst_n,
    input  wire tready,
    output reg  tvalid,
    output reg  tlast
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tvalid <= 1'b0;
            tlast  <= 1'b0;
        end else if (tready) begin
            tvalid <= 1'b1;
            tlast  <= 1'b0; // For continuous streaming, TLAST is held low
        end else begin
            tvalid <= tvalid;
            tlast  <= tlast;
        end
    end
endmodule