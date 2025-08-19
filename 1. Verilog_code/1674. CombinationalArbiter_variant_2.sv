//SystemVerilog
module CombinationalArbiter #(parameter N=4) (
    input [N-1:0] req,
    output [N-1:0] grant
);

// Two's complement adder implementation
reg [N-1:0] mask;
reg [N-1:0] req_comp;
reg [N-1:0] one = 1;

// Generate two's complement of req
always @(*) begin
    req_comp = ~req + one;
end

// Add req and its two's complement
always @(*) begin
    mask = req + req_comp;
end

assign grant = req & ~mask;

endmodule