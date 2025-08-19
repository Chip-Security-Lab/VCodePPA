//SystemVerilog
// -----------------------------------------------------------------------------
// Top-level Module: shift_preload
// Function: Shift register with parallel preload, using hierarchical structure
// -----------------------------------------------------------------------------
module shift_preload #(parameter WIDTH = 8) (
    input                    clk,
    input                    load,
    input      [WIDTH-1:0]   load_data,
    output     [WIDTH-1:0]   sr
);

    wire [WIDTH-1:0] sr_next;
    wire [WIDTH-1:0] sr_reg_out;

    // Control logic: determines next value for the shift register
    shift_preload_ctrl #(.WIDTH(WIDTH)) u_ctrl (
        .load         (load),
        .load_data    (load_data),
        .sr_in        (sr_reg_out),
        .next_sr      (sr_next)
    );

    // Register unit: stores the shift register value
    shift_preload_reg #(.WIDTH(WIDTH)) u_reg (
        .clk          (clk),
        .data_in      (sr_next),
        .data_out     (sr_reg_out)
    );

    assign sr = sr_reg_out;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_preload_ctrl
// Function: Combinational logic to generate the next shift register value
// -----------------------------------------------------------------------------
module shift_preload_ctrl #(parameter WIDTH = 8) (
    input                    load,
    input      [WIDTH-1:0]   load_data,
    input      [WIDTH-1:0]   sr_in,
    output reg [WIDTH-1:0]   next_sr
);
    // Control logic: preload or shift
    always @* begin
        if (load)
            next_sr = load_data;
        else
            next_sr = {sr_in[WIDTH-2:0], 1'b0};
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_preload_reg
// Function: Sequential register to hold the shift register value
// -----------------------------------------------------------------------------
module shift_preload_reg #(parameter WIDTH = 8) (
    input                    clk,
    input      [WIDTH-1:0]   data_in,
    output reg [WIDTH-1:0]   data_out
);
    // Register update on positive clock edge
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule