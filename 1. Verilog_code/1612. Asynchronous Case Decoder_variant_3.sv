//SystemVerilog
// Address decoder submodule
module address_decoder #(
    parameter AW = 3
)(
    input wire [AW-1:0] address,
    output reg [2**AW-1:0] decoded
);
    always @(*) begin
        decoded = 1'b1 << address;
    end
endmodule

// Output formatter submodule
module output_formatter #(
    parameter AW = 3,
    parameter DW = 8
)(
    input wire [2**AW-1:0] decoded,
    output reg [DW-1:0] formatted
);
    always @(*) begin
        formatted = {DW{1'b0}};
        if (AW <= $clog2(DW)) begin
            formatted = decoded[DW-1:0];
        end else begin
            formatted = decoded[2**AW-1:2**AW-DW];
        end
    end
endmodule

// Top-level module
module async_case_decoder #(
    parameter AW = 3,
    parameter DW = 8
)(
    input wire [AW-1:0] address,
    output wire [DW-1:0] select
);
    wire [2**AW-1:0] decoded_signal;
    
    // Instantiate address decoder submodule
    address_decoder #(
        .AW(AW)
    ) addr_decoder_inst (
        .address(address),
        .decoded(decoded_signal)
    );
    
    // Instantiate output formatter submodule
    output_formatter #(
        .AW(AW),
        .DW(DW)
    ) out_formatter_inst (
        .decoded(decoded_signal),
        .formatted(select)
    );
endmodule