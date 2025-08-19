//SystemVerilog
// Top-level module: Structured pipelined binary to one-hot encoder
module binary_to_onehot #(
    parameter BINARY_WIDTH = 3
)(
    input  wire                          clk,
    input  wire                          rst_n,
    input  wire [BINARY_WIDTH-1:0]       binary_in,
    output wire [(1<<BINARY_WIDTH)-1:0]  onehot_out
);

    // Stage 1: Input register for binary value
    reg [BINARY_WIDTH-1:0]   binary_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_stage1 <= {BINARY_WIDTH{1'b0}};
        else
            binary_stage1 <= binary_in;
    end

    // Stage 2: Combinational binary-to-onehot encoding
    wire [(1<<BINARY_WIDTH)-1:0] onehot_stage2;
    assign onehot_stage2 = ({{(1<<BINARY_WIDTH)-1{1'b0}}, 1'b1} << binary_stage1);

    // Stage 3: Register the one-hot output for timing closure
    reg [(1<<BINARY_WIDTH)-1:0] onehot_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_stage3 <= {(1<<BINARY_WIDTH){1'b0}};
        else
            onehot_stage3 <= onehot_stage2;
    end

    // Output assignment (registered one-hot code)
    assign onehot_out = onehot_stage3;

endmodule