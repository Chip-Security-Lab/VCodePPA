//SystemVerilog
// Top-level module for shift enable chain with hierarchical structure
module shift_enable_chain #(parameter WIDTH=8) (
    input  wire                 clk,
    input  wire                 en,
    input  wire [WIDTH-1:0]     din,
    output wire [WIDTH-1:0]     dout
);

    wire [WIDTH-1:0] buffer_data_out;
    wire [WIDTH-1:0] shift_data_out;

    // Buffer Register Submodule: Latches input data when enabled
    buffer_register #(.WIDTH(WIDTH)) u_buffer_register (
        .clk        (clk),
        .en         (en),
        .data_in    (din),
        .data_out   (buffer_data_out)
    );

    // Shift Logic Submodule: Shifts buffer and outputs result when enabled
    shift_logic #(.WIDTH(WIDTH)) u_shift_logic (
        .clk        (clk),
        .en         (en),
        .buffer_in  (buffer_data_out),
        .shift_out  (shift_data_out)
    );

    assign dout = shift_data_out;

endmodule

// -----------------------------------------------------------------------------
// Buffer Register Submodule
// Latches input data to buffer on rising edge of clk when enabled
// -----------------------------------------------------------------------------
module buffer_register #(parameter WIDTH=8) (
    input  wire                 clk,
    input  wire                 en,
    input  wire [WIDTH-1:0]     data_in,
    output reg  [WIDTH-1:0]     data_out
);
    always @(posedge clk) begin
        data_out <= en ? data_in : data_out;
    end
endmodule

// -----------------------------------------------------------------------------
// Shift Logic Submodule
// On enable, shifts buffer_in left by 1 and fills LSB with 0
// Holds previous value when not enabled
// -----------------------------------------------------------------------------
module shift_logic #(parameter WIDTH=8) (
    input  wire                 clk,
    input  wire                 en,
    input  wire [WIDTH-1:0]     buffer_in,
    output reg  [WIDTH-1:0]     shift_out
);
    always @(posedge clk) begin
        shift_out <= en ? {buffer_in[WIDTH-2:0], 1'b0} : shift_out;
    end
endmodule