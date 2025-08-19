module status_buffer (
    input wire clk,
    input wire [7:0] status_in,
    input wire update,
    input wire clear,
    output reg [7:0] status_out
);
    always @(posedge clk) begin
        if (clear)
            status_out <= 8'b0;
        else if (update)
            status_out <= status_out | status_in; // Set bits
    end
endmodule