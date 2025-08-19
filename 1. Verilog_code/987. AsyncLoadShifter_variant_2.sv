//SystemVerilog
// Top-level module: Hierarchical AsyncLoadShifter
module AsyncLoadShifter #(parameter WIDTH=8) (
    input wire clk,
    input wire async_load,
    input wire [WIDTH-1:0] load_data,
    output wire [WIDTH-1:0] data_reg
);

    wire [WIDTH-1:0] shifter_out;
    wire [WIDTH-1:0] mux_out;

    // Submodule: LoadMux
    // Selects between asynchronous load data and shifted data
    LoadMux #(.WIDTH(WIDTH)) u_load_mux (
        .async_load(async_load),
        .load_data(load_data),
        .shifted_data(shifter_out),
        .mux_out(mux_out)
    );

    // Submodule: AsyncRegister
    // Flip-flop register with asynchronous load
    AsyncRegister #(.WIDTH(WIDTH)) u_async_register (
        .clk(clk),
        .async_load(async_load),
        .d(mux_out),
        .q(data_reg)
    );

    // Submodule: LeftShifter
    // Performs left shift by one bit with zero fill
    LeftShifter #(.WIDTH(WIDTH)) u_left_shifter (
        .in(data_reg),
        .shifted_out(shifter_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: LoadMux
// Selects between asynchronous load data and shifted data
module LoadMux #(parameter WIDTH=8) (
    input wire async_load,
    input wire [WIDTH-1:0] load_data,
    input wire [WIDTH-1:0] shifted_data,
    output wire [WIDTH-1:0] mux_out
);
    assign mux_out = async_load ? load_data : shifted_data;
endmodule

// -----------------------------------------------------------------------------
// Submodule: AsyncRegister
// Flip-flop register with asynchronous load capability
module AsyncRegister #(parameter WIDTH=8) (
    input wire clk,
    input wire async_load,
    input wire [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge async_load) begin
        if (async_load)
            q <= d;
        else
            q <= d;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: LeftShifter
// Performs left shift by one bit with zero fill
module LeftShifter #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] shifted_out
);
    assign shifted_out = {in[WIDTH-2:0], 1'b0};
endmodule