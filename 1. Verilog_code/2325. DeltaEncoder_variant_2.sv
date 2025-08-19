//SystemVerilog
module DeltaEncoder (
    input wire clk, 
    input wire rst_n,
    input wire [15:0] din,
    output reg [15:0] dout
);
    reg [15:0] prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev <= 16'h0;
            dout <= 16'h0;
        end else begin
            prev <= din;
            dout <= din - prev;
        end
    end
endmodule