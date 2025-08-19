//SystemVerilog
// Top-level parameterizable demux module with hierarchical structure

module param_demux #(
    parameter OUTPUT_COUNT = 8,         // Number of output lines
    parameter ADDR_WIDTH = 3            // Address width (log2 of outputs)
) (
    input  wire                        clk,            // Pipeline clock
    input  wire                        rst_n,          // Active-low synchronous reset
    input  wire                        data_input,     // Single data input
    input  wire [ADDR_WIDTH-1:0]       addr,           // Address selection
    output wire [OUTPUT_COUNT-1:0]     out             // Multiple outputs
);

    // Stage 1: Input Registering
    wire                               reg_data_out;
    wire [ADDR_WIDTH-1:0]              reg_addr_out;

    demux_input_register #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_input_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (data_input),
        .addr_in    (addr),
        .data_out   (reg_data_out),
        .addr_out   (reg_addr_out)
    );

    // Stage 2: One-hot Decoder
    wire [OUTPUT_COUNT-1:0]            one_hot_out;

    demux_one_hot_decoder #(
        .OUTPUT_COUNT(OUTPUT_COUNT),
        .ADDR_WIDTH  (ADDR_WIDTH)
    ) u_one_hot_decoder (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (reg_data_out),
        .addr_in    (reg_addr_out),
        .one_hot_out(one_hot_out)
    );

    // Stage 3: Output Register
    demux_output_register #(
        .OUTPUT_COUNT(OUTPUT_COUNT)
    ) u_output_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (one_hot_out),
        .data_out   (out)
    );

endmodule

//------------------------------------------------------------------------------
// Input Register Module
// Registers the input data and address for pipelining
//------------------------------------------------------------------------------
module demux_input_register #(
    parameter ADDR_WIDTH = 3
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  data_in,
    input  wire [ADDR_WIDTH-1:0] addr_in,
    output reg                   data_out,
    output reg  [ADDR_WIDTH-1:0] addr_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            addr_out <= {ADDR_WIDTH{1'b0}};
        end else begin
            data_out <= data_in;
            addr_out <= addr_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// One-hot Decoder Module
// Decodes address and data to generate one-hot output vector
//------------------------------------------------------------------------------
module demux_one_hot_decoder #(
    parameter OUTPUT_COUNT = 8,
    parameter ADDR_WIDTH  = 3
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  data_in,
    input  wire [ADDR_WIDTH-1:0] addr_in,
    output reg  [OUTPUT_COUNT-1:0] one_hot_out
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            one_hot_out <= {OUTPUT_COUNT{1'b0}};
        end else begin
            if (data_in) begin
                one_hot_out <= {OUTPUT_COUNT{1'b0}};
                one_hot_out[addr_in] <= 1'b1;
            end else begin
                one_hot_out <= {OUTPUT_COUNT{1'b0}};
            end
        end
    end
endmodule

//------------------------------------------------------------------------------
// Output Register Module
// Registers the final one-hot decoded output for pipelining
//------------------------------------------------------------------------------
module demux_output_register #(
    parameter OUTPUT_COUNT = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [OUTPUT_COUNT-1:0] data_in,
    output reg  [OUTPUT_COUNT-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUTPUT_COUNT{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// 3-bit Parallel Prefix Subtractor (Kogge-Stone based) Module
//------------------------------------------------------------------------------
module parallel_prefix_subtractor_3bit (
    input  wire [2:0] minuend,
    input  wire [2:0] subtrahend,
    input  wire       borrow_in,
    output wire [2:0] difference,
    output wire       borrow_out
);
    // Generate and Propagate signals
    wire [2:0] gen;
    wire [2:0] prop;

    assign gen[0] = (~minuend[0]) & subtrahend[0];
    assign prop[0] = ~(minuend[0] ^ subtrahend[0]);

    assign gen[1] = (~minuend[1]) & subtrahend[1];
    assign prop[1] = ~(minuend[1] ^ subtrahend[1]);

    assign gen[2] = (~minuend[2]) & subtrahend[2];
    assign prop[2] = ~(minuend[2] ^ subtrahend[2]);

    // Prefix computation (Kogge-Stone style)
    wire [2:0] borrow;

    // Level 0
    assign borrow[0] = gen[0] | (prop[0] & borrow_in);

    // Level 1
    wire g1_0, p1_0;
    assign g1_0 = gen[1] | (prop[1] & gen[0]);
    assign p1_0 = prop[1] & prop[0];
    assign borrow[1] = g1_0 | (p1_0 & borrow_in);

    // Level 2
    wire g2_1, p2_1;
    assign g2_1 = gen[2] | (prop[2] & gen[1]);
    assign p2_1 = prop[2] & prop[1];

    wire g2_0, p2_0;
    assign g2_0 = g2_1 | (p2_1 & gen[0]);
    assign p2_0 = p2_1 & prop[0];

    assign borrow[2] = g2_0 | (p2_0 & borrow_in);

    // Difference calculation
    assign difference[0] = minuend[0] ^ subtrahend[0] ^ borrow_in;
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];

    assign borrow_out = borrow[2];

endmodule