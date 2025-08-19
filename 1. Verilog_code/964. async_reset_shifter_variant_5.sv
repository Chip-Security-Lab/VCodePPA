//SystemVerilog
module async_reset_shifter #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output wire o_data
);
    // 使用专用SHREG属性以便更好地匹配FPGA架构中的移位寄存器资源
    (* shreg_extract = "yes", use_dsp = "no", async_reg = "true" *) 
    reg [WIDTH-1:0] r_shifter;
    
    // 优化异步复位逻辑，确保优先级清晰
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n) begin
            // 使用参数化复位值以提高综合工具识别率
            r_shifter <= {WIDTH{1'b0}};
        end 
        else if (i_en) begin
            // 使用拼接操作实现移位，明确数据流向
            r_shifter <= {i_data, r_shifter[WIDTH-1:1]};
        end
    end
    
    // 直接访问寄存器最低位作为输出，减少额外逻辑
    assign o_data = r_shifter[0];
endmodule