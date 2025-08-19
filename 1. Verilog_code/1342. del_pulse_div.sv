module del_pulse_div #(parameter N=3) (
    input clk, rst,
    output reg clk_out
);
reg [2:0] cnt;

// Use standard positive-edge triggered division
always @(posedge clk or posedge rst) begin
    if(rst) begin
        cnt <= 0;
        clk_out <= 0;
    end else if(cnt == N-1) begin
        cnt <= 0;
        clk_out <= ~clk_out;
    end else begin
        cnt <= cnt + 1;
    end
end
endmodule