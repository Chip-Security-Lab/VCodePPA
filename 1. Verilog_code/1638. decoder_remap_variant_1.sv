//SystemVerilog
module borrow_subtractor (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] result,
    output reg [8:0] borrow
);

    always @(*) begin
        borrow[0] = 0;
        result[0] = a[0] ^ b[0] ^ borrow[0];
        borrow[1] = (~a[0] & b[0]) | (~a[0] & borrow[0]) | (b[0] & borrow[0]);
        
        result[1] = a[1] ^ b[1] ^ borrow[1];
        borrow[2] = (~a[1] & b[1]) | (~a[1] & borrow[1]) | (b[1] & borrow[1]);
        
        result[2] = a[2] ^ b[2] ^ borrow[2];
        borrow[3] = (~a[2] & b[2]) | (~a[2] & borrow[2]) | (b[2] & borrow[2]);
        
        result[3] = a[3] ^ b[3] ^ borrow[3];
        borrow[4] = (~a[3] & b[3]) | (~a[3] & borrow[3]) | (b[3] & borrow[3]);
        
        result[4] = a[4] ^ b[4] ^ borrow[4];
        borrow[5] = (~a[4] & b[4]) | (~a[4] & borrow[4]) | (b[4] & borrow[4]);
        
        result[5] = a[5] ^ b[5] ^ borrow[5];
        borrow[6] = (~a[5] & b[5]) | (~a[5] & borrow[5]) | (b[5] & borrow[5]);
        
        result[6] = a[6] ^ b[6] ^ borrow[6];
        borrow[7] = (~a[6] & b[6]) | (~a[6] & borrow[6]) | (b[6] & borrow[6]);
        
        result[7] = a[7] ^ b[7] ^ borrow[7];
        borrow[8] = (~a[7] & b[7]) | (~a[7] & borrow[7]) | (b[7] & borrow[7]);
    end

endmodule

module address_comparator (
    input [7:0] addr,
    output reg select
);

    always @(*) begin
        select = (addr < 8'h10);
    end

endmodule

module decoder_remap (
    input clk,
    input [7:0] base_addr,
    input [7:0] addr,
    output reg select
);

    wire [7:0] mapped_addr;
    wire [8:0] borrow;

    borrow_subtractor subtractor (
        .a(addr),
        .b(base_addr),
        .result(mapped_addr),
        .borrow(borrow)
    );

    address_comparator comparator (
        .addr(mapped_addr),
        .select(select)
    );

endmodule