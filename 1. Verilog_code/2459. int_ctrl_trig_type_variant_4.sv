//SystemVerilog
module int_ctrl_trig_type #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire [WIDTH-1:0] int_src,
    input  wire [WIDTH-1:0] trig_type,  // 0=level 1=edge
    output wire [WIDTH-1:0] int_out
);
    // 分离电平触发和边沿触发的信号处理路径
    reg [WIDTH-1:0] sync_reg_level;
    reg [WIDTH-1:0] sync_reg_edge, prev_reg_edge;
    
    // 针对不同触发类型优化采样逻辑
    always @(posedge clk) begin
        // 电平触发路径 - 只需要当前状态
        sync_reg_level <= int_src;
        
        // 边沿触发路径 - 需要当前和前一个状态
        sync_reg_edge <= int_src;
        prev_reg_edge <= sync_reg_edge;
    end
    
    // 生成边沿检测信号 - 优化比较逻辑
    wire [WIDTH-1:0] edge_detect;
    
    // 为每一位独立计算边沿检测，减少逻辑层级
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : edge_detect_gen
            assign edge_detect[i] = sync_reg_edge[i] & ~prev_reg_edge[i];
        end
    endgenerate
    
    // 使用位选择操作生成最终输出，避免使用大型多路复用器
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : output_mux_gen
            assign int_out[i] = trig_type[i] ? edge_detect[i] : sync_reg_level[i];
        end
    endgenerate
    
endmodule