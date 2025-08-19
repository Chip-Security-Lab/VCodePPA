module TimeoutMatcher #(parameter WIDTH=8, TIMEOUT=100) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg timeout
);
reg [15:0] counter;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        timeout <= 0;
    end else begin
        counter <= (data == pattern) ? 0 : counter + 1;
        timeout <= (counter >= TIMEOUT);
    end
end
endmodule
