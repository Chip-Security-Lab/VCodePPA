module async_case_decoder #(
    parameter AW = 3,
    parameter DW = 8
)(
    input wire [AW-1:0] address,
    output reg [DW-1:0] select
);
    always @(*) begin
        select = 8'h00;
        case (address)
            3'b000: select = 8'h01;
            3'b001: select = 8'h02;
            3'b010: select = 8'h04;
            3'b011: select = 8'h08;
            3'b100: select = 8'h10;
            3'b101: select = 8'h20;
            3'b110: select = 8'h40;
            3'b111: select = 8'h80;
        endcase
    end
endmodule