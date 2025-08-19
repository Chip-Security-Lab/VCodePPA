module usb_bit_stuffer(
    input wire clk_i,
    input wire rst_i,
    input wire bit_i,
    input wire valid_i,
    output reg bit_o,
    output reg valid_o,
    output reg stuffed_o
);
    localparam MAX_ONES = 6;
    reg [2:0] ones_count;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            ones_count <= 3'd0;
            bit_o <= 1'b0;
            valid_o <= 1'b0;
            stuffed_o <= 1'b0;
        end else if (valid_i) begin
            if (bit_i == 1'b1) begin
                ones_count <= ones_count + 1'b1;
                if (ones_count == MAX_ONES-1) begin
                    bit_o <= 1'b0;
                    valid_o <= 1'b1;
                    stuffed_o <= 1'b1;
                    ones_count <= 3'd0;
                end else begin
                    bit_o <= bit_i;
                    valid_o <= 1'b1;
                    stuffed_o <= 1'b0;
                end
            end else begin
                ones_count <= 3'd0;
                bit_o <= bit_i;
                valid_o <= 1'b1;
                stuffed_o <= 1'b0;
            end
        end else begin
            valid_o <= 1'b0;
            stuffed_o <= 1'b0;
        end
    end
endmodule