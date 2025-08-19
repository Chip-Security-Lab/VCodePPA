//SystemVerilog
module packet_parser #(parameter DW=32) (
    input clk, valid,
    input [DW-1:0] packet,
    output reg [7:0] header,
    output reg [15:0] payload
);

    reg [7:0] header_comb;
    reg [15:0] payload_comb;

    always @* begin
        header_comb  = packet[31:24];
        payload_comb = packet[23:8];
    end

    always @(posedge clk) begin
        if(valid) begin
            header  <= header_comb;
            payload <= payload_comb;
        end
    end

endmodule