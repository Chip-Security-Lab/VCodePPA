module scan_d_ff (
    input wire clk,
    input wire rst_n,
    input wire scan_en,
    input wire scan_in,
    input wire d,
    output reg q,
    output wire scan_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= scan_en ? scan_in : d;
    end
    
    assign scan_out = q;
endmodule