//SystemVerilog
module usb_nrzi_encoder (
    input wire clk,
    input wire en,
    input wire data,
    output reg tx
);
    // Perform NRZI encoding directly with combinational logic
    wire nrzi_result;
    assign nrzi_result = data ? tx : ~tx;
    
    // Single pipeline stage register
    always @(posedge clk) begin
        if (en) begin
            tx <= nrzi_result;
        end
    end
endmodule