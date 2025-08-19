module gray_counter #(parameter WIDTH = 4) (
    input wire clk, reset, enable,
    output reg [WIDTH-1:0] gray_out
);
    reg [WIDTH-1:0] binary;
    
    always @(posedge clk) begin
        if (reset) begin
            binary <= 0;
            gray_out <= 0;
        end else if (enable) begin
            binary <= binary + 1'b1;
            gray_out <= (binary >> 1) ^ binary;
        end
    end
endmodule