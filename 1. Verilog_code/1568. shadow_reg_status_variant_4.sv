//SystemVerilog
module shadow_reg_status #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg valid
);
    reg [DW-1:0] shadow_reg;
    reg [DW-1:0] subtracted_value;
    wire [DW-1:0] inverted_data;
    wire [DW:0] temp_result;
    
    // 二进制补码减法实现 (data_in - shadow_reg)
    assign inverted_data = ~shadow_reg;
    assign temp_result = {1'b0, data_in} + {1'b0, inverted_data} + 1'b1;
    
    always @(posedge clk) begin
        if(rst) begin
            data_out <= {DW{1'b0}};
            valid <= 1'b0;
            shadow_reg <= {DW{1'b0}};
            subtracted_value <= {DW{1'b0}};
        end
        else if(en) begin
            shadow_reg <= data_in;
            subtracted_value <= temp_result[DW-1:0]; // 存储减法结果
            valid <= 1'b0;
        end
        else begin
            data_out <= subtracted_value; // 输出减法结果而不是shadow_reg
            valid <= 1'b1;
        end
    end
endmodule