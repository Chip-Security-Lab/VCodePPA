//SystemVerilog
module TriStateLatch #(parameter BITS=8) (
    input clk, rst_n, oe,
    input [BITS-1:0] d,
    output [BITS-1:0] q
);

reg [BITS-1:0] data_stage1;
reg [BITS-1:0] data_stage2;
reg valid_stage1;
reg valid_stage2;
wire [BITS-1:0] mux_out;

// Stage 1: Input register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage1 <= {BITS{1'b0}};
        valid_stage1 <= 1'b0;
    end else begin
        data_stage1 <= d;
        valid_stage1 <= 1'b1;
    end
end

// Stage 2: Processing register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2 <= {BITS{1'b0}};
        valid_stage2 <= 1'b0;
    end else begin
        data_stage2 <= data_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Explicit multiplexer implementation
assign mux_out = (valid_stage2 && oe) ? data_stage2 : {BITS{1'b0}};
assign q = (valid_stage2 && oe) ? mux_out : {BITS{1'bz}};

endmodule