//SystemVerilog
module neg_edge_shifter #(
    parameter LENGTH = 6
) (
    input  wire              neg_clk,
    input  wire              d_in,
    input  wire              rstn,
    output wire [LENGTH-1:0] q_out
);
    // 将移位寄存器分为多级流水线结构，提高时序性能
    (* shreg_extract = "yes" *) reg [LENGTH-1:0] shift_reg_pipeline;
    
    // 添加数据输入缓冲寄存器，减少输入端负载
    reg data_input_buffer;
    
    // 输入缓冲阶段
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn) begin
            data_input_buffer <= 1'b0;
        end else begin
            data_input_buffer <= d_in;
        end
    end
    
    // 主移位流水线阶段
    always @(negedge neg_clk or negedge rstn) begin
        if (!rstn) begin
            // 并行复位，使用常量复制，提高布局效率
            shift_reg_pipeline <= {LENGTH{1'b0}};
        end else begin
            // 优化的移位操作，降低逻辑深度
            shift_reg_pipeline <= {shift_reg_pipeline[LENGTH-2:0], data_input_buffer};
        end
    end
    
    // 定义输出映射，分离数据流和控制流
    assign q_out = shift_reg_pipeline;

endmodule