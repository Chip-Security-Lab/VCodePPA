//SystemVerilog
// Top-level module: bit_shuffler_pipeline
module bit_shuffler_pipeline #(
    parameter WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      data_in,
    input  wire [1:0]            shuffle_mode,
    output wire [WIDTH-1:0]      data_out
);

    // Pipeline stage 1: Input Register
    reg [WIDTH-1:0] data_in_stage1;
    reg [1:0]       shuffle_mode_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1       <= {WIDTH{1'b0}};
            shuffle_mode_stage1  <= 2'b00;
        end else begin
            data_in_stage1       <= data_in;
            shuffle_mode_stage1  <= shuffle_mode;
        end
    end

    // Pipeline stage 2: Parallel Data Transformations
    wire [WIDTH-1:0] unchanged_stage2;
    wire [WIDTH-1:0] swap_nibble_stage2;
    wire [WIDTH-1:0] rotate2_stage2;
    wire [WIDTH-1:0] rotate6_stage2;

    shuffler_unchanged #(.WIDTH(WIDTH)) u_unchanged (
        .data_in(data_in_stage1),
        .data_out(unchanged_stage2)
    );

    shuffler_swap_nibble #(.WIDTH(WIDTH)) u_swap_nibble (
        .data_in(data_in_stage1),
        .data_out(swap_nibble_stage2)
    );

    shuffler_right_rotate #(.WIDTH(WIDTH), .SHIFT(2)) u_right_rotate2 (
        .data_in(data_in_stage1),
        .data_out(rotate2_stage2)
    );

    shuffler_right_rotate #(.WIDTH(WIDTH), .SHIFT(6)) u_right_rotate6 (
        .data_in(data_in_stage1),
        .data_out(rotate6_stage2)
    );

    // Pipeline stage 3: Register transformation results and mode
    reg [WIDTH-1:0] unchanged_stage3;
    reg [WIDTH-1:0] swap_nibble_stage3;
    reg [WIDTH-1:0] rotate2_stage3;
    reg [WIDTH-1:0] rotate6_stage3;
    reg [1:0]       shuffle_mode_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unchanged_stage3     <= {WIDTH{1'b0}};
            swap_nibble_stage3   <= {WIDTH{1'b0}};
            rotate2_stage3       <= {WIDTH{1'b0}};
            rotate6_stage3       <= {WIDTH{1'b0}};
            shuffle_mode_stage3  <= 2'b00;
        end else begin
            unchanged_stage3     <= unchanged_stage2;
            swap_nibble_stage3   <= swap_nibble_stage2;
            rotate2_stage3       <= rotate2_stage2;
            rotate6_stage3       <= rotate6_stage2;
            shuffle_mode_stage3  <= shuffle_mode_stage1;
        end
    end

    // Pipeline stage 4: Output Selection
    reg [WIDTH-1:0] data_out_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage4 <= {WIDTH{1'b0}};
        end else begin
            case (shuffle_mode_stage3)
                2'b00: data_out_stage4 <= unchanged_stage3;
                2'b01: data_out_stage4 <= swap_nibble_stage3;
                2'b10: data_out_stage4 <= rotate2_stage3;
                2'b11: data_out_stage4 <= rotate6_stage3;
                default: data_out_stage4 <= {WIDTH{1'bx}};
            endcase
        end
    end

    assign data_out = data_out_stage4;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shuffler_unchanged
// Function: Pass-through, outputs input unchanged
// -----------------------------------------------------------------------------
module shuffler_unchanged #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = data_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: shuffler_swap_nibble
// Function: Swaps the lower and upper 4 bits (for WIDTH=8)
// -----------------------------------------------------------------------------
module shuffler_swap_nibble #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = {data_in[3:0], data_in[7:4]};
endmodule

// -----------------------------------------------------------------------------
// Submodule: shuffler_right_rotate
// Function: Cyclically right rotates input by SHIFT bits
// -----------------------------------------------------------------------------
module shuffler_right_rotate #(
    parameter WIDTH = 8,
    parameter SHIFT = 2
)(
    input  wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = {data_in[SHIFT-1:0], data_in[WIDTH-1:SHIFT]};
endmodule

// -----------------------------------------------------------------------------
// Submodule: subtractor_4bit_twos_complement
// Function: 4-bit subtraction using two's complement addition
// -----------------------------------------------------------------------------
module subtractor_4bit_twos_complement (
    input  wire [3:0] operand_a,
    input  wire [3:0] operand_b,
    output wire [3:0] diff,
    output wire       borrow_out
);
    wire [3:0] operand_b_inverted;
    wire [4:0] addition_result;

    assign operand_b_inverted = ~operand_b;
    assign addition_result = {1'b0, operand_a} + {1'b0, operand_b_inverted} + 5'b00001;
    assign diff = addition_result[3:0];
    assign borrow_out = ~addition_result[4];
endmodule