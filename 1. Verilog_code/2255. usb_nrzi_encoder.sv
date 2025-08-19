module usb_nrzi_encoder (
    input clk, en,
    input data,
    output reg tx
);
    reg last_bit;
    always @(posedge clk) begin
        if(en) begin
            tx <= data ? last_bit : ~last_bit;
            last_bit <= tx;
        end
    end
endmodule