module compact_hamming(
    input i_clk, i_rst, i_en,
    input [3:0] i_data,
    output reg [6:0] o_code
);
    always @(posedge i_clk) begin
        if (i_rst) o_code <= 7'b0;
        else if (i_en) begin
            o_code <= {i_data[3:1], 
                      ^{i_data[1], i_data[2], i_data[3]}, 
                      i_data[0], 
                      ^{i_data[0], i_data[2], i_data[3]}, 
                      ^{i_data[0], i_data[1], i_data[3]}};
        end
    end
endmodule