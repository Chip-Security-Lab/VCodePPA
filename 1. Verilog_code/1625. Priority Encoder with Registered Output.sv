module priority_encoder_reg (
    input clk,
    input [7:0] requests,
    output reg [2:0] grant_id,
    output reg valid
);
    always @(posedge clk) begin
        valid <= |requests;
        if (requests[0]) grant_id <= 3'd0;
        else if (requests[1]) grant_id <= 3'd1;
        else if (requests[2]) grant_id <= 3'd2;
        else if (requests[3]) grant_id <= 3'd3;
        else if (requests[4]) grant_id <= 3'd4;
        else if (requests[5]) grant_id <= 3'd5;
        else if (requests[6]) grant_id <= 3'd6;
        else if (requests[7]) grant_id <= 3'd7;
        else grant_id <= 3'd0;
    end
endmodule