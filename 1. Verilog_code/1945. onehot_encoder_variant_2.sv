//SystemVerilog
// Top-level: Pipelined and Structured One-Hot Encoder (Modularized Always Blocks)

module onehot_encoder #(
    parameter IN_WIDTH = 4
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [IN_WIDTH-1:0]       binary_in,
    input  wire                      valid_in,
    output wire [(1<<IN_WIDTH)-1:0]  onehot_out,
    output wire                      error
);

    // Stage 1: Input Registering
    reg [IN_WIDTH-1:0]          binary_in_stage1;
    reg                         valid_in_stage1;

    // Stage 2: Range Check Pipeline
    wire                        is_valid_index_stage2;
    reg  [IN_WIDTH-1:0]         binary_in_stage2;
    reg                         valid_in_stage2;

    // Stage 3: One-Hot Generation Pipeline
    wire [(1<<IN_WIDTH)-1:0]    onehot_value_stage3;
    reg  [(1<<IN_WIDTH)-1:0]    onehot_out_stage3;
    reg                         error_stage3;

    // Stage 1: Input Pipeline Register (binary_in)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_in_stage1 <= {IN_WIDTH{1'b0}};
        end else begin
            binary_in_stage1 <= binary_in;
        end
    end

    // Stage 1: Input Pipeline Register (valid_in)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_stage1  <= 1'b0;
        end else begin
            valid_in_stage1  <= valid_in;
        end
    end

    // Stage 2: Range Checker Submodule
    range_checker #(
        .IN_WIDTH(IN_WIDTH)
    ) u_range_checker (
        .binary_in(binary_in_stage1),
        .valid_in(valid_in_stage1),
        .is_valid_index(is_valid_index_stage2)
    );

    // Stage 2: Pipeline Register (binary_in)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_in_stage2 <= {IN_WIDTH{1'b0}};
        end else begin
            binary_in_stage2 <= binary_in_stage1;
        end
    end

    // Stage 2: Pipeline Register (valid_in)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_stage2  <= 1'b0;
        end else begin
            valid_in_stage2  <= valid_in_stage1;
        end
    end

    // Stage 3: One-Hot Generator Submodule
    onehot_generator #(
        .IN_WIDTH(IN_WIDTH)
    ) u_onehot_generator (
        .binary_in(binary_in_stage2),
        .enable(valid_in_stage2 & is_valid_index_stage2),
        .onehot_out(onehot_value_stage3)
    );

    // Stage 3: Pipeline Register (onehot_out)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onehot_out_stage3 <= {((1<<IN_WIDTH)){1'b0}};
        end else begin
            onehot_out_stage3 <= onehot_value_stage3;
        end
    end

    // Stage 3: Pipeline Register (error)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_stage3      <= 1'b0;
        end else begin
            error_stage3      <= error_signal(binary_in_stage2, valid_in_stage2, is_valid_index_stage2);
        end
    end

    // Output Assignment
    assign onehot_out = onehot_out_stage3;
    assign error      = error_stage3;

    // Error signal combinational function
    function error_signal;
        input [IN_WIDTH-1:0] binary_in_f;
        input                valid_in_f;
        input                is_valid_index_f;
        begin
            error_signal = valid_in_f & ~is_valid_index_f;
        end
    endfunction

endmodule

// -----------------------------------------------------------------------------
// Submodule: Range Checker
// Checks if binary_in is within the legal range [0, 2^IN_WIDTH-1]
// -----------------------------------------------------------------------------
module range_checker #(
    parameter IN_WIDTH = 4
)(
    input  wire [IN_WIDTH-1:0] binary_in,
    input  wire                valid_in,
    output wire                is_valid_index
);
    assign is_valid_index = (binary_in < (1<<IN_WIDTH));
endmodule

// -----------------------------------------------------------------------------
// Submodule: Onehot Generator
// Outputs one-hot vector if enable is asserted
// -----------------------------------------------------------------------------
module onehot_generator #(
    parameter IN_WIDTH = 4
)(
    input  wire [IN_WIDTH-1:0] binary_in,
    input  wire                enable,
    output wire [(1<<IN_WIDTH)-1:0] onehot_out
);
    assign onehot_out = (enable) ? (1'b1 << binary_in) : {((1<<IN_WIDTH)){1'b0}};
endmodule