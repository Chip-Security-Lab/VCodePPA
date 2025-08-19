module TimeoutRecovery #(parameter WIDTH=8, TIMEOUT=32'hFFFF) (
    input clk, rst_n,
    input [WIDTH-1:0] unstable_in,
    output reg [WIDTH-1:0] stable_out,
    output reg timeout
);
    reg [31:0] counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            stable_out <= 0;
            timeout <= 0;
        end else begin
            counter <= (unstable_in != stable_out) ? 0 : counter + 1;
            timeout <= (counter >= TIMEOUT);
            stable_out <= (counter >= TIMEOUT) ? stable_out : unstable_in;
        end
    end
endmodule
