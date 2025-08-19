module gray_signal_recovery (
    input clk,
    input enable,
    input [3:0] gray_in,
    output reg [3:0] binary_out,
    output reg valid
);
    reg [3:0] prev_gray;
    wire [3:0] decoded;
    
    assign decoded[3] = gray_in[3];
    assign decoded[2] = decoded[3] ^ gray_in[2];
    assign decoded[1] = decoded[2] ^ gray_in[1];
    assign decoded[0] = decoded[1] ^ gray_in[0];
    
    always @(posedge clk) begin
        if (enable) begin
            binary_out <= decoded;
            prev_gray <= gray_in;
            valid <= (prev_gray != gray_in);
        end else begin
            valid <= 1'b0;
        end
    end
endmodule