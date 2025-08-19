//SystemVerilog
module packet_parser #(parameter DW=32) (
    input clk,
    input valid,
    input [DW-1:0] packet,
    output [7:0] header,
    output [15:0] payload
);

    reg [DW-1:0] packet_reg;

    always @(posedge clk) begin
        if(valid) begin
            packet_reg <= packet;
        end
    end

    assign header  = packet_reg[31:24];
    assign payload = packet_reg[23:8];

endmodule