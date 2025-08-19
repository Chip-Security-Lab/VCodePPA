module feistel_network #(parameter HALF_WIDTH = 16) (
    input wire clk, rst_n, enable,
    input wire [HALF_WIDTH-1:0] left_in, right_in,
    input wire [HALF_WIDTH-1:0] round_key,
    output reg [HALF_WIDTH-1:0] left_out, right_out
);
    wire [HALF_WIDTH-1:0] f_output;
    
    // Simple F function (could be more complex)
    assign f_output = right_in ^ round_key;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            left_out <= 0;
            right_out <= 0;
        end else if (enable) begin
            left_out <= right_in;
            right_out <= left_in ^ f_output;
        end
    end
endmodule