//SystemVerilog
module async_reset_shifter #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output wire o_data
);
    reg [WIDTH-2:0] r_shifter;  // 移除一位，因为输入寄存器移动了
    reg r_data_in;  // 新增寄存器，捕获输入数据
    
    // 输入寄存器 - 移动到数据路径前端
    always @(posedge i_clk or negedge i_arst_n) begin: input_reg_proc
        if (!i_arst_n) begin
            r_data_in <= 1'b0;
        end else if (i_en) begin
            r_data_in <= i_data;
        end
    end
    
    // 主移位寄存器 - 现在少一位
    always @(posedge i_clk or negedge i_arst_n) begin: shift_proc
        if (!i_arst_n) begin
            r_shifter <= {(WIDTH-1){1'b0}};
        end else begin
            if (i_en) begin
                // 通过显式地指定每个位的赋值提高布线效率
                r_shifter[0] <= r_shifter[1];
                r_shifter[WIDTH-3:1] <= r_shifter[WIDTH-2:2];
                r_shifter[WIDTH-2] <= r_data_in;  // 使用寄存过的输入
            end
        end
    end
    
    assign o_data = r_shifter[0];
endmodule