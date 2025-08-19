//SystemVerilog
// Top-level interrupt controller module
module int_ctrl_vectored #(
    parameter VEC_W = 16
)(
    input                  clk,      // System clock
    input                  rst,      // System reset
    input  [VEC_W-1:0]     int_in,   // Interrupt input vector
    input  [VEC_W-1:0]     mask_reg, // Interrupt mask register
    output [VEC_W-1:0]     int_out   // Masked interrupt output
);

    // Internal signals for connecting sub-modules
    wire [VEC_W-1:0] synchronized_int;
    wire [VEC_W-1:0] synchronized_mask;
    wire [VEC_W-1:0] pending_interrupts;

    // Input synchronizer module instantiation
    int_synchronizer #(
        .WIDTH(VEC_W)
    ) sync_stage (
        .clk           (clk),
        .rst           (rst),
        .int_in        (int_in),
        .mask_in       (mask_reg),
        .int_sync_out  (synchronized_int),
        .mask_sync_out (synchronized_mask)
    );

    // Interrupt pending logic module instantiation
    int_pending_logic #(
        .WIDTH(VEC_W)
    ) pending_stage (
        .clk           (clk),
        .rst           (rst),
        .int_in        (synchronized_int),
        .mask_in       (synchronized_mask),
        .pending_out   (pending_interrupts)
    );

    // Output stage module instantiation
    int_output_stage #(
        .WIDTH(VEC_W)
    ) out_stage (
        .clk           (clk),
        .rst           (rst),
        .pending_in    (pending_interrupts),
        .int_out       (int_out)
    );

endmodule

// Input synchronizer module
module int_synchronizer #(
    parameter WIDTH = 16
)(
    input                    clk,          // System clock
    input                    rst,          // System reset
    input      [WIDTH-1:0]   int_in,       // Raw interrupt inputs
    input      [WIDTH-1:0]   mask_in,      // Raw mask inputs
    output reg [WIDTH-1:0]   int_sync_out, // Synchronized interrupt
    output reg [WIDTH-1:0]   mask_sync_out // Synchronized mask
);

    // Synchronize interrupt inputs and mask
    always @(posedge clk) begin
        if (rst) begin
            int_sync_out  <= {WIDTH{1'b0}};
            mask_sync_out <= {WIDTH{1'b0}};
        end else begin
            int_sync_out  <= int_in;
            mask_sync_out <= mask_in;
        end
    end

endmodule

// Interrupt pending logic module
module int_pending_logic #(
    parameter WIDTH = 16
)(
    input                    clk,         // System clock
    input                    rst,         // System reset
    input      [WIDTH-1:0]   int_in,      // Synchronized interrupt inputs
    input      [WIDTH-1:0]   mask_in,     // Synchronized mask inputs
    output reg [WIDTH-1:0]   pending_out  // Pending interrupt outputs
);

    // Update pending register based on incoming interrupts and mask
    always @(posedge clk) begin
        if (rst) begin
            pending_out <= {WIDTH{1'b0}};
        end else begin
            pending_out <= (pending_out | int_in) & mask_in;
        end
    end

endmodule

// Output stage module
module int_output_stage #(
    parameter WIDTH = 16
)(
    input                    clk,        // System clock
    input                    rst,        // System reset
    input      [WIDTH-1:0]   pending_in, // Pending interrupt inputs
    output reg [WIDTH-1:0]   int_out     // Final masked interrupt outputs
);

    // Register the output to improve timing
    always @(posedge clk) begin
        if (rst) begin
            int_out <= {WIDTH{1'b0}};
        end else begin
            int_out <= pending_in;
        end
    end

endmodule