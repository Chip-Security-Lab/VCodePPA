module sync_pos_edge_reg(
    input clk, rst_n,
    input [7:0] data_in,
    input load_en,
    output reg [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (load_en)
            data_out <= data_in;
    end
endmodule