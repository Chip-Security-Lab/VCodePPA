//SystemVerilog
module scan_d_ff (
    input  wire clk,
    input  wire rst_n,
    input  wire scan_en,
    input  wire scan_in,
    input  wire d,
    output reg  q,
    output wire scan_out
);
    // IEEE 1364-2005 Verilog标准
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
        end
        else begin
            if (scan_en) begin
                q <= scan_in;
            end
            else begin
                q <= d;
            end
        end
    end
    
    assign scan_out = q;
endmodule