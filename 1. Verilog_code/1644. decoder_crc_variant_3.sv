//SystemVerilog
module crc_calculator #(parameter WIDTH=8) (
    input [WIDTH-1:0] addr,
    input [WIDTH-1:0] data,
    output [WIDTH-1:0] crc
);
    assign crc = addr ^ data;
endmodule

module address_matcher #(parameter WIDTH=8) (
    input [WIDTH-1:0] addr,
    output match
);
    assign match = (addr[7:4] == 4'b1010);
endmodule

module crc_verifier #(parameter WIDTH=8) (
    input [WIDTH-1:0] crc,
    output match
);
    assign match = (crc == 8'h55);
endmodule

module decoder_crc #(parameter AW=8, DW=8) (
    input [AW-1:0] addr,
    input [DW-1:0] data,
    output select
);
    wire [7:0] crc;
    wire addr_match;
    wire crc_match;
    
    crc_calculator #(.WIDTH(8)) crc_calc (
        .addr(addr),
        .data(data),
        .crc(crc)
    );
    
    address_matcher #(.WIDTH(8)) addr_match_inst (
        .addr(addr),
        .match(addr_match)
    );
    
    crc_verifier #(.WIDTH(8)) crc_verify (
        .crc(crc),
        .match(crc_match)
    );
    
    assign select = addr_match && crc_match;
endmodule