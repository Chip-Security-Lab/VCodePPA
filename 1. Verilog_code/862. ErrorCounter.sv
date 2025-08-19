module ErrorCounter #(parameter WIDTH=8, MAX_ERR=3) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg alarm
);
reg [3:0] err_count;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        err_count <= 0;
        alarm <= 0;
    end else begin
        err_count <= (data != pattern) ? err_count + 1 : 0;
        alarm <= (err_count >= MAX_ERR);
    end
end
endmodule
