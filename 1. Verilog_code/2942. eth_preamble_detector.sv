module eth_preamble_detector (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_dv,
    output reg preamble_detected,
    output reg sfd_detected
);
    localparam PREAMBLE_BYTE = 8'h55;
    localparam SFD_BYTE = 8'hD5;
    
    reg [2:0] preamble_count;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            preamble_count <= 3'd0;
            preamble_detected <= 1'b0;
            sfd_detected <= 1'b0;
        end else if (rx_dv) begin
            if (rx_data == PREAMBLE_BYTE) begin
                if (preamble_count < 7)
                    preamble_count <= preamble_count + 1'b1;
                    
                if (preamble_count >= 2)
                    preamble_detected <= 1'b1;
            end else if (rx_data == SFD_BYTE && preamble_count >= 6) begin
                sfd_detected <= 1'b1;
                preamble_count <= 3'd0;
            end else begin
                preamble_count <= 3'd0;
                preamble_detected <= 1'b0;
                sfd_detected <= 1'b0;
            end
        end else begin
            preamble_detected <= 1'b0;
            sfd_detected <= 1'b0;
        end
    end
endmodule