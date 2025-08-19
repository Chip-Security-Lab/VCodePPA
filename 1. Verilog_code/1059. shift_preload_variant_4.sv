//SystemVerilog
// Top-level shift register with preload logic, hierarchical structure

module shift_preload #(parameter WIDTH=8) (
    input clk,
    input load,
    input [WIDTH-1:0] load_data,
    output [WIDTH-1:0] sr
);

    // Internal wire for next shift register value
    wire [WIDTH-1:0] next_sr;

    // Instantiate next value logic submodule
    shift_preload_nextval #(.WIDTH(WIDTH)) u_nextval (
        .load      (load),
        .load_data (load_data),
        .sr_in     (sr),
        .next_sr   (next_sr)
    );

    // Instantiate register submodule
    shift_preload_reg #(.WIDTH(WIDTH)) u_reg (
        .clk     (clk),
        .d       (next_sr),
        .q       (sr)
    );

endmodule

// -----------------------------------------------------------------------------
// shift_preload_nextval
// Description: Combinational logic to determine next shift register value
// -----------------------------------------------------------------------------
module shift_preload_nextval #(parameter WIDTH=8) (
    input                  load,
    input  [WIDTH-1:0]     load_data,
    input  [WIDTH-1:0]     sr_in,
    output reg [WIDTH-1:0] next_sr
);
    always @* begin
        if (load)
            next_sr = load_data;
        else
            next_sr = {sr_in[WIDTH-2:0], 1'b0};
    end
endmodule

// -----------------------------------------------------------------------------
// shift_preload_reg
// Description: Synchronous register for shift register state storage
// -----------------------------------------------------------------------------
module shift_preload_reg #(parameter WIDTH=8) (
    input               clk,
    input  [WIDTH-1:0]  d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        q <= d;
    end
endmodule