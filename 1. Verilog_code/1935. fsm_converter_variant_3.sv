//SystemVerilog
// -----------------------------------------------------------------------------
// Top-level FSM Converter Module (Hierarchical, Parameterized, IEEE 1364-2005)
// -----------------------------------------------------------------------------
module fsm_converter #(parameter S_WIDTH = 4) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire [S_WIDTH-1:0]             state_in,
    output wire [(1<<S_WIDTH)-1:0]        state_one_hot
);

    // Stage 1: Input Register
    wire [S_WIDTH-1:0] state_in_reg_out;

    input_register #(
        .WIDTH(S_WIDTH)
    ) u_input_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (state_in),
        .data_out   (state_in_reg_out)
    );

    // Stage 2: One-hot Encoder (combinational)
    wire [(1<<S_WIDTH)-1:0] one_hot_code;

    one_hot_encoder #(
        .WIDTH(S_WIDTH)
    ) u_one_hot_encoder (
        .binary_in  (state_in_reg_out),
        .one_hot_out(one_hot_code)
    );

    // Stage 3: Output Register
    output_register #(
        .WIDTH((1<<S_WIDTH))
    ) u_output_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (one_hot_code),
        .data_out   (state_one_hot)
    );

endmodule

// -----------------------------------------------------------------------------
// Input Register Submodule
// Pipeline stage 1: Registers the input binary state.
// -----------------------------------------------------------------------------
module input_register #(parameter WIDTH = 4) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule

// -----------------------------------------------------------------------------
// One-hot Encoder Submodule (Combinational)
// Converts a binary input to a one-hot code.
// -----------------------------------------------------------------------------
module one_hot_encoder #(parameter WIDTH = 4) (
    input  wire [WIDTH-1:0]      binary_in,
    output reg  [(1<<WIDTH)-1:0] one_hot_out
);
    integer i;
    always @(*) begin
        for (i = 0; i < (1<<WIDTH); i = i + 1) begin
            one_hot_out[i] = (i == binary_in) ? 1'b1 : 1'b0;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Output Register Submodule
// Pipeline stage 3: Registers the one-hot output.
// -----------------------------------------------------------------------------
module output_register #(parameter WIDTH = 16) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else
            data_out <= data_in;
    end
endmodule