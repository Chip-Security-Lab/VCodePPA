//SystemVerilog
// Top-level module: Hierarchical Gray Code Queue with Parity (Optimized)
module gray_queue #(parameter DW=8) (
    input                  clk,
    input                  rst,
    input                  en,
    input  [DW-1:0]        din,
    output reg [DW-1:0]    dout,
    output reg             error
);

    // Internal wires and registers
    wire                   parity_bit;
    wire [DW:0]            gray_in;
    wire [DW:0]            queue_out;

    // Parity calculation submodule
    parity_calc #(.DW(DW)) u_parity_calc (
        .data_in   (din),
        .parity_out(parity_bit)
    );

    // Gray input packing submodule
    gray_pack #(.DW(DW)) u_gray_pack (
        .data_in   (din),
        .parity_in (parity_bit),
        .gray_out  (gray_in)
    );

    // Queue storage submodule
    queue_storage #(.DW(DW)) u_queue_storage (
        .clk      (clk),
        .rst      (rst),
        .en       (en),
        .data_in  (gray_in),
        .data_out (queue_out)
    );

    // Output unpacking and error checking submodule
    output_unpack #(.DW(DW)) u_output_unpack (
        .queue_in (queue_out),
        .data_out (dout_wire),
        .error_out(error_wire)
    );

    // Registered outputs to maintain timing and avoid race conditions
    wire [DW-1:0] dout_wire;
    wire          error_wire;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout  <= {DW{1'b0}};
            error <= 1'b0;
        end else if (en) begin
            dout  <= dout_wire;
            error <= error_wire;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Submodule: Parity Calculation (Optimized)
// Calculates the odd parity of the input data using reduction XOR
// -----------------------------------------------------------------------------
module parity_calc #(parameter DW=8) (
    input  [DW-1:0] data_in,
    output          parity_out
);
    assign parity_out = ^data_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: Gray Code Input Packing
// Packs data and parity into a single word
// -----------------------------------------------------------------------------
module gray_pack #(parameter DW=8) (
    input  [DW-1:0] data_in,
    input           parity_in,
    output [DW:0]   gray_out
);
    assign gray_out = {data_in, parity_in};
endmodule

// -----------------------------------------------------------------------------
// Submodule: Queue Storage
// 2-stage pipeline queue for gray code data
// -----------------------------------------------------------------------------
module queue_storage #(parameter DW=8) (
    input              clk,
    input              rst,
    input              en,
    input  [DW:0]      data_in,
    output reg [DW:0]  data_out
);
    reg [DW:0] queue_stage0, queue_stage1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            queue_stage0 <= {(DW+1){1'b0}};
            queue_stage1 <= {(DW+1){1'b0}};
            data_out     <= {(DW+1){1'b0}};
        end else if (en) begin
            queue_stage0 <= data_in;
            queue_stage1 <= queue_stage0;
            data_out     <= queue_stage1;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: Output Unpacking and Error Checking (Optimized)
// Extracts data and performs parity check for error detection using reduction XOR
// -----------------------------------------------------------------------------
module output_unpack #(parameter DW=8) (
    input  [DW:0]     queue_in,
    output [DW-1:0]   data_out,
    output            error_out
);
    assign data_out  = queue_in[DW:1];
    assign error_out = (^queue_in[DW:1]) ^ queue_in[0];
endmodule