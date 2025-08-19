//SystemVerilog
// Top-level module for shift enable chain
module shift_enable_chain #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                en,
    input  wire [WIDTH-1:0]    din,
    output wire [WIDTH-1:0]    dout
);

    // Internal signal for buffer register output
    wire [WIDTH-1:0] buffer_out;

    // Buffer Register Submodule
    buffer_register #(
        .WIDTH(WIDTH)
    ) u_buffer_register (
        .clk    (clk),
        .en     (en),
        .din    (din),
        .buffer (buffer_out)
    );

    // Shift Logic Submodule
    shift_logic #(
        .WIDTH(WIDTH)
    ) u_shift_logic (
        .clk    (clk),
        .en     (en),
        .buffer (buffer_out),
        .dout   (dout)
    );

endmodule

// ---------------------------------------------------------------------------
// Buffer Register Module
// Stores input data on enable
// ---------------------------------------------------------------------------
module buffer_register #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                en,
    input  wire [WIDTH-1:0]    din,
    output reg  [WIDTH-1:0]    buffer
);
    always @(posedge clk) begin
        if (en)
            buffer <= din;
        else
            buffer <= buffer;
    end
endmodule

// ---------------------------------------------------------------------------
// Shift Logic Module
// Performs left shift and outputs result on enable
// ---------------------------------------------------------------------------
module shift_logic #(parameter WIDTH=8) (
    input  wire                clk,
    input  wire                en,
    input  wire [WIDTH-1:0]    buffer,
    output reg  [WIDTH-1:0]    dout
);
    always @(posedge clk) begin
        if (en)
            dout <= {buffer[WIDTH-2:0], 1'b0};
        else
            dout <= dout;
    end
endmodule