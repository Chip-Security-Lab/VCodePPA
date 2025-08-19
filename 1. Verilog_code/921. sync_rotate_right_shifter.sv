module sync_rotate_right_shifter (
    input              clk_i,
    input              arst_n,  // Active low async reset
    input      [31:0]  data_i,
    input      [4:0]   shift_i,
    output reg [31:0]  data_o
);
    // Calculate rotation amount
    wire [31:0] rotated;
    
    // Right rotation implementation using concatenation
    assign rotated = {data_i, data_i} >> shift_i;
    
    // Synchronous update with asynchronous reset
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n)
            data_o <= 32'h0;
        else
            data_o <= rotated;
    end
endmodule