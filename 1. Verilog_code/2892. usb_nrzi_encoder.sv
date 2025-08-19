module usb_nrzi_encoder(
    input wire clk,
    input wire reset,
    input wire data_in,
    input wire valid_in,
    output reg data_out,
    output reg valid_out
);
    reg last_bit;
    
    always @(posedge clk) begin
        if (reset) begin
            data_out <= 1'b1;
            last_bit <= 1'b1;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            valid_out <= 1'b1;
            if (data_in == 1'b0) begin
                data_out <= ~last_bit;
                last_bit <= ~last_bit;
            end else begin
                data_out <= last_bit;
            end
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule