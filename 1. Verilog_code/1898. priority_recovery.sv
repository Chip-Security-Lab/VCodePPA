module priority_recovery (
    input wire clk,
    input wire enable,
    input wire [7:0] signals,
    output reg [2:0] recovered_idx,
    output reg valid
);
    always @(posedge clk) begin
        if (enable) begin
            valid <= |signals;
            casez (signals)
                8'b1???????: recovered_idx <= 3'd7;
                8'b01??????: recovered_idx <= 3'd6;
                8'b001?????: recovered_idx <= 3'd5;
                8'b0001????: recovered_idx <= 3'd4;
                8'b00001???: recovered_idx <= 3'd3;
                8'b000001??: recovered_idx <= 3'd2;
                8'b0000001?: recovered_idx <= 3'd1;
                8'b00000001: recovered_idx <= 3'd0;
                default: valid <= 1'b0;
            endcase
        end else begin
            valid <= 1'b0;
        end
    end
endmodule