module RegBypassBridge #(
    parameter WIDTH = 32
)(
    input clk, rst_n,
    input [WIDTH-1:0] reg_in,
    output reg [WIDTH-1:0] reg_out,
    input bypass_en
);
    always @(posedge clk) begin
        if (bypass_en) 
            reg_out <= reg_in;
        else 
            reg_out <= reg_out;
    end
endmodule