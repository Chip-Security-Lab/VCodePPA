module one_hot_load_reg(
    input clk, rst_n,
    input [23:0] data_word,
    input [2:0] load_select,  // One-hot encoded
    output reg [23:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 24'h0;
        else begin
            case (load_select)
                3'b001: data_out[7:0] <= data_word[7:0];
                3'b010: data_out[15:8] <= data_word[15:8];
                3'b100: data_out[23:16] <= data_word[23:16];
                default: data_out <= data_out;  // Hold value
            endcase
        end
    end
endmodule