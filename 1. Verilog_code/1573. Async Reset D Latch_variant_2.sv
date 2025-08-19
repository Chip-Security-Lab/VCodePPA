//SystemVerilog
module d_latch_async_rst (
    input wire d,
    input wire enable,
    input wire rst_n,    // Active low reset
    output reg q
);
    reg [1:0] control;
    
    always @* begin
        control = {rst_n, enable};
        
        case (control)
            2'b00: q = 1'b0;    // Reset active (rst_n = 0), enable = 0
            2'b01: q = 1'b0;    // Reset active (rst_n = 0), enable = 1
            2'b10: q = q;       // Reset inactive, enable = 0 (hold value)
            2'b11: q = d;       // Reset inactive, enable = 1 (pass d)
        endcase
    end
endmodule