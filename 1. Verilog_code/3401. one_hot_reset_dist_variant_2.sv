//SystemVerilog
module one_hot_reset_dist(
    input wire clk,
    input wire [1:0] reset_select,
    input wire reset_in,
    output reg [3:0] reset_out
);
    // Use decoded one-hot approach for better PPA
    reg [3:0] decoded_select;
    
    always @(*) begin
        decoded_select = 4'b0000;
        decoded_select[reset_select] = 1'b1;
    end
    
    always @(posedge clk) begin
        if (reset_in)
            reset_out <= decoded_select;
        else
            reset_out <= 4'b0000;
    end
endmodule