//SystemVerilog
// Top-level module: Pipelined 16-bit Bus OR operation
module BusOR(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [15:0]  bus_a,
    input  wire [15:0]  bus_b,
    output wire [15:0]  bus_or
);
    // Stage 1: Input Registering
    wire [15:0] bus_a_stage1;
    wire [15:0] bus_b_stage1;

    BusOR_InputReg u_input_reg (
        .clk      (clk),
        .rst_n    (rst_n),
        .in_bus_a (bus_a),
        .in_bus_b (bus_b),
        .out_bus_a(bus_a_stage1),
        .out_bus_b(bus_b_stage1)
    );

    // Stage 2: OR Logic
    wire [15:0] bus_or_stage2;

    BusOR_Logic #(.WIDTH(16)) u_bus_or_logic (
        .in_a  (bus_a_stage1),
        .in_b  (bus_b_stage1),
        .out_or(bus_or_stage2)
    );

    // Stage 3: Output Registering
    BusOR_OutputReg u_output_reg (
        .clk       (clk),
        .rst_n     (rst_n),
        .in_bus_or (bus_or_stage2),
        .out_bus_or(bus_or)
    );
endmodule

// -----------------------------------------------------------------------------
// Submodule: BusOR_InputReg
// Description: Pipeline register for input bus signals (Stage 1)
// -----------------------------------------------------------------------------
module BusOR_InputReg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] in_bus_a,
    input  wire [15:0] in_bus_b,
    output reg  [15:0] out_bus_a,
    output reg  [15:0] out_bus_b
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_bus_a <= 16'b0;
            out_bus_b <= 16'b0;
        end else begin
            out_bus_a <= in_bus_a;
            out_bus_b <= in_bus_b;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: BusOR_Logic
// Description: Parameterized bitwise OR logic for bus signals (Stage 2)
// -----------------------------------------------------------------------------
module BusOR_Logic #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] in_a,
    input  wire [WIDTH-1:0] in_b,
    output wire [WIDTH-1:0] out_or
);
    assign out_or = in_a | in_b;
endmodule

// -----------------------------------------------------------------------------
// Submodule: BusOR_OutputReg
// Description: Pipeline register for OR result (Stage 3)
// -----------------------------------------------------------------------------
module BusOR_OutputReg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] in_bus_or,
    output reg  [15:0] out_bus_or
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_bus_or <= 16'b0;
        else
            out_bus_or <= in_bus_or;
    end
endmodule