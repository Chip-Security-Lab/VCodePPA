//SystemVerilog
module usb_nrzi_encoder (
    input clk, en,
    input data,
    output reg tx
);
    reg last_bit;
    
    always @(posedge clk) begin
        if(en) begin
            // Direct calculation in the register logic, removing the intermediate signal
            tx <= data ? last_bit : ~last_bit;
            last_bit <= data ? last_bit : ~last_bit;
        end
    end
endmodule