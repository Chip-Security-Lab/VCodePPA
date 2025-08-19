//SystemVerilog
module Comparator_Approximate #(
    parameter WIDTH = 10,
    parameter THRESHOLD = 3
)(
    input  [WIDTH-1:0] data_p,
    input  [WIDTH-1:0] data_q,
    output             approx_eq
);
    reg [WIDTH-1:0] minuend;
    reg [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] subtrahend_inv;
    wire [WIDTH-1:0] diff;
    
    always @(*) begin
        if (data_p > data_q) begin
            minuend = data_p;
            subtrahend = data_q;
        end
        else begin
            minuend = data_q;
            subtrahend = data_p;
        end
    end
    
    assign subtrahend_inv = ~subtrahend;
    assign diff = minuend + subtrahend_inv + 1'b1;
    assign approx_eq = (diff <= THRESHOLD);
endmodule