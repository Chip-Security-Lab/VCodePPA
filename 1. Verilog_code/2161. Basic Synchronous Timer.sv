module basic_sync_timer #(parameter WIDTH = 32)(
    input wire clk, rst_n, enable,
    output reg [WIDTH-1:0] count,
    output reg timeout
);
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else if (enable) begin
            count <= count + 1'b1;
            timeout <= (count == {WIDTH{1'b1}});
        end
    end
endmodule