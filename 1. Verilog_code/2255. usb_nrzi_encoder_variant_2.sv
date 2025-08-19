//SystemVerilog
//IEEE 1364-2005
module usb_nrzi_encoder (
    input clk, en,
    input data,
    output reg tx
);
    reg last_bit;
    
    always @(posedge clk) begin
        if(en && data) begin
            tx <= last_bit;
            last_bit <= last_bit;
        end else if(en && !data) begin
            tx <= ~last_bit;
            last_bit <= ~last_bit;
        end
    end
endmodule