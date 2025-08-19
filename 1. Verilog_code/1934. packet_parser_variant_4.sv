//SystemVerilog
module packet_parser #(parameter DW=32) (
    input wire clk,
    input wire valid,
    input wire [DW-1:0] packet,
    output reg [7:0] header,
    output reg [15:0] payload
);

    reg [DW-1:0] packet_reg;

    always @(posedge clk) begin
        if (valid) begin
            packet_reg <= packet;
        end
    end

    always @(posedge clk) begin
        if (valid) begin
            header  <= packet_reg[31:24];
            payload <= packet_reg[23:8];
        end
    end

endmodule