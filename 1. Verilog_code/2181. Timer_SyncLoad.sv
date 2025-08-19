module Timer_SyncLoad #(parameter WIDTH=8) (
    input clk, rst_n, enable,
    input [WIDTH-1:0] preset,
    output reg timeout
);
    reg [WIDTH-1:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 0;
        else if (enable) cnt <= (cnt == preset) ? 0 : cnt + 1;
        timeout <= (cnt == preset);
    end
endmodule