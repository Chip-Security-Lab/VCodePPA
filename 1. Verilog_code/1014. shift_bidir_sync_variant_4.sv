//SystemVerilog
// Top-level module: Hierarchical and modularized bidirectional shift register

module shift_bidir_sync #(parameter WIDTH = 16) (
    input wire clk,
    input wire rst,
    input wire dir,  // 0:left, 1:right
    input wire [WIDTH-1:0] din,
    output wire [WIDTH-1:0] dout
);

    // Internal signal for shifted data
    wire [WIDTH-1:0] shifted_data;
    // Internal signal for output register
    wire [WIDTH-1:0] reg_out;

    // Shift Logic Submodule Instance
    shift_logic #(.WIDTH(WIDTH)) u_shift_logic (
        .shift_dir(dir),
        .data_in(din),
        .data_out(shifted_data)
    );

    // Output Register Submodule Instance
    sync_register #(.WIDTH(WIDTH)) u_sync_register (
        .clk(clk),
        .rst(rst),
        .d(shifted_data),
        .q(reg_out)
    );

    assign dout = reg_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_logic
// Function: Performs a one-bit left or right shift based on the direction input
// -----------------------------------------------------------------------------
module shift_logic #(parameter WIDTH = 16) (
    input wire shift_dir,                // 0:left, 1:right
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = shift_dir ? (data_in >> 1) : (data_in << 1);
endmodule

// -----------------------------------------------------------------------------
// Submodule: sync_register
// Function: Synchronous register with asynchronous reset
// -----------------------------------------------------------------------------
module sync_register #(parameter WIDTH = 16) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else begin
            q <= d;
        end
    end
endmodule