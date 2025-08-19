//SystemVerilog
// Top-level: Hierarchical pipelined binary-to-onehot encoder

module bin2onehot_pipeline #(
    parameter IN_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     valid_in,
    input  wire [IN_WIDTH-1:0]      bin_in,
    output wire                     valid_out,
    output reg  [(2**IN_WIDTH)-1:0] onehot_out
);

    // Internal pipeline signals
    wire [IN_WIDTH-1:0]             bin_in_stage1;
    wire                            valid_stage1;
    wire [(2**IN_WIDTH)-1:0]        onehot_stage2;
    wire                            valid_stage2;
    wire [(2**IN_WIDTH)-1:0]        onehot_stage3;
    wire                            valid_stage3;

    // Stage 1: Input Register
    bin2onehot_stage1_reg #(
        .IN_WIDTH(IN_WIDTH)
    ) u_stage1_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .bin_in     (bin_in),
        .valid_in   (valid_in),
        .bin_out    (bin_in_stage1),
        .valid_out  (valid_stage1)
    );

    // Stage 2: One-hot Calculation
    bin2onehot_stage2_encode #(
        .IN_WIDTH(IN_WIDTH)
    ) u_stage2_encode (
        .clk            (clk),
        .rst_n          (rst_n),
        .bin_in         (bin_in_stage1),
        .valid_in       (valid_stage1),
        .onehot_out     (onehot_stage2),
        .valid_out      (valid_stage2)
    );

    // Stage 3: Output Register
    bin2onehot_stage3_reg #(
        .IN_WIDTH(IN_WIDTH)
    ) u_stage3_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .onehot_in      (onehot_stage2),
        .valid_in       (valid_stage2),
        .onehot_out     (onehot_stage3),
        .valid_out      (valid_stage3)
    );

    assign valid_out = valid_stage3;

    // Output register with output enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_out <= {(2**IN_WIDTH){1'b0}};
        else if (valid_stage3)
            onehot_out <= onehot_stage3;
    end

endmodule

//------------------------------------------------------------------------------
// Stage 1: Input register stage
// Captures binary input and valid signal
//------------------------------------------------------------------------------
module bin2onehot_stage1_reg #(
    parameter IN_WIDTH = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [IN_WIDTH-1:0]  bin_in,
    input  wire                 valid_in,
    output reg  [IN_WIDTH-1:0]  bin_out,
    output reg                  valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_out   <= {IN_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            bin_out   <= bin_in;
            valid_out <= valid_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Stage 2: One-hot encoding stage
// Performs one-hot calculation on registered binary input
//------------------------------------------------------------------------------
module bin2onehot_stage2_encode #(
    parameter IN_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [IN_WIDTH-1:0]      bin_in,
    input  wire                     valid_in,
    output reg  [(2**IN_WIDTH)-1:0] onehot_out,
    output reg                      valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onehot_out <= {(2**IN_WIDTH){1'b0}};
            valid_out  <= 1'b0;
        end else begin
            onehot_out <= ({{(2**IN_WIDTH-1){1'b0}}, 1'b1} << bin_in);
            valid_out  <= valid_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Stage 3: Output register stage
// Registers one-hot output and valid signal for output stage
//------------------------------------------------------------------------------
module bin2onehot_stage3_reg #(
    parameter IN_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [(2**IN_WIDTH)-1:0] onehot_in,
    input  wire                     valid_in,
    output reg  [(2**IN_WIDTH)-1:0] onehot_out,
    output reg                      valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            onehot_out <= {(2**IN_WIDTH){1'b0}};
            valid_out  <= 1'b0;
        end else begin
            onehot_out <= onehot_in;
            valid_out  <= valid_in;
        end
    end
endmodule