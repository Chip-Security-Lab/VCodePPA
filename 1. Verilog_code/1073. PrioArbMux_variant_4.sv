//SystemVerilog
module PrioArbMux #(parameter DW=4) (
    input  [3:0] req,
    input        en,
    output reg [1:0] grant,
    output     [DW-1:0] data
);

wire [3:0] minuend;
wire [3:0] subtrahend;
wire       borrow_in;
wire [3:0] diff;
wire       borrow_out;

// Priority encoding
always @* begin
    if (en) begin
        if (req[3]) begin
            grant = 2'b11;
        end else if (req[2]) begin
            grant = 2'b10;
        end else if (req[1]) begin
            grant = 2'b01;
        end else begin
            grant = 2'b00;
        end
    end else begin
        grant = 2'b00;
    end
end

// Example subtraction operands for demonstration (can be replaced as needed)
assign minuend    = 4'b1010;
assign subtrahend = 4'b0111;
assign borrow_in  = 1'b0;

// 4-bit Parallel Borrow Lookahead Subtractor
wire [3:0] generate_borrow;
wire [3:0] propagate_borrow;
wire [3:0] borrow;

// Generate and propagate signals
assign generate_borrow[0] = ~minuend[0] & subtrahend[0];
assign propagate_borrow[0] = ~(minuend[0] ^ subtrahend[0]);

assign generate_borrow[1] = ~minuend[1] & subtrahend[1];
assign propagate_borrow[1] = ~(minuend[1] ^ subtrahend[1]);

assign generate_borrow[2] = ~minuend[2] & subtrahend[2];
assign propagate_borrow[2] = ~(minuend[2] ^ subtrahend[2]);

assign generate_borrow[3] = ~minuend[3] & subtrahend[3];
assign propagate_borrow[3] = ~(minuend[3] ^ subtrahend[3]);

// Borrow chain
assign borrow[0] = generate_borrow[0] | (propagate_borrow[0] & borrow_in);
assign borrow[1] = generate_borrow[1] | (propagate_borrow[1] & borrow[0]);
assign borrow[2] = generate_borrow[2] | (propagate_borrow[2] & borrow[1]);
assign borrow[3] = generate_borrow[3] | (propagate_borrow[3] & borrow[2]);
assign borrow_out = borrow[3];

// Difference bits
assign diff[0] = minuend[0] ^ subtrahend[0] ^ borrow_in;
assign diff[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
assign diff[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
assign diff[3] = minuend[3] ^ subtrahend[3] ^ borrow[2];

// Output result (can be mapped to 'data' as required)
assign data = {grant, {DW-2{1'b0}}};

endmodule