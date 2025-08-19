//SystemVerilog
// Top-level module: shift_saturation
// Function: Performs arithmetic right shift with saturation, using parallel prefix subtractor

module shift_saturation #(parameter W=8) (
    input  wire                     clk,
    input  wire signed [W-1:0]      din,
    input  wire [2:0]               shift,
    output reg  signed [W-1:0]      dout
);

    wire signed [W-1:0]             shifted_value;
    wire                            saturate_condition;
    wire signed [W-1:0]             saturated_output;
    wire [2:0]                      subtrahend;
    wire [2:0]                      sub_result;

    // Subtrahend is the shift amount
    assign subtrahend = shift;

    // 3-bit parallel prefix subtractor for shift >= W comparison
    parallel_prefix_subtractor_3bit u_pps3 (
        .a(subtrahend),
        .b(W[2:0]),
        .borrow_out(borrow_out),
        .diff(sub_result)
    );

    // Saturation condition: shift >= W
    assign saturate_condition = (borrow_out == 1'b0);

    assign shifted_value = din >>> shift;
    assign saturated_output = {W{1'b0}};

    always @(posedge clk) begin
        if (saturate_condition)
            dout <= saturated_output;
        else
            dout <= shifted_value;
    end

endmodule

// 3-bit Parallel Prefix Subtractor
module parallel_prefix_subtractor_3bit (
    input  wire [2:0] a,
    input  wire [2:0] b,
    output wire       borrow_out,
    output wire [2:0] diff
);
    // Generate and Propagate signals
    wire [2:0] g; // generate
    wire [2:0] p; // propagate
    wire [3:0] c; // borrow chain

    assign g[0] = (~a[0]) & b[0];
    assign p[0] = ~(a[0] ^ b[0]);
    assign g[1] = (~a[1]) & b[1];
    assign p[1] = ~(a[1] ^ b[1]);
    assign g[2] = (~a[2]) & b[2];
    assign p[2] = ~(a[2] ^ b[2]);

    assign c[0] = 1'b0;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);

    assign diff[0] = a[0] ^ b[0] ^ c[0];
    assign diff[1] = a[1] ^ b[1] ^ c[1];
    assign diff[2] = a[2] ^ b[2] ^ c[2];
    assign borrow_out = c[3];

endmodule