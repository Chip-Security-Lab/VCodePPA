module packet_parser #(parameter DW=32) (
    input clk, valid,
    input [DW-1:0] packet,
    output reg [7:0] header,
    output reg [15:0] payload
);
    always @(posedge clk) if(valid) begin
        header <= packet[31:24];
        payload <= packet[23:8];
    end
endmodule
