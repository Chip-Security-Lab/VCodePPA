module manchester_encoder (
    input clk, rst_n,
    input data_in,
    output reg encoded_out
);
    reg data_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 1'b0;
            encoded_out <= 1'b0;
        end else begin
            data_reg <= data_in;
            // 避免使用clk作为数据信号
            if (data_reg)
                encoded_out <= ~encoded_out;
        end
    end
endmodule