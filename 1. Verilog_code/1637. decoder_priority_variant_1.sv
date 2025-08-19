//SystemVerilog
module decoder_priority #(WIDTH=4) (
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);

wire [WIDTH-1:0] mask;
wire [WIDTH-1:0] masked_req;

// Generate mask for priority encoding
assign mask = req & (~req + 1);
assign masked_req = req & mask;

// Priority encoder using case statement
always @* begin
    case (1'b1)
        masked_req[0]: grant = 0;
        masked_req[1]: grant = 1;
        masked_req[2]: grant = 2;
        masked_req[3]: grant = 3;
        default: grant = 0;
    endcase
end

endmodule