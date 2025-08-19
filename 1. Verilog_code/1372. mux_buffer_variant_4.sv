//SystemVerilog
module mux_buffer (
    input  wire        clk,
    input  wire [1:0]  select,
    input  wire [7:0]  data_a, data_b, data_c, data_d,
    input  wire        valid_in,
    output wire        ready_in,
    output wire        valid_out,
    input  wire        ready_out,
    output wire [7:0]  data_out
);
    // 缓冲区状态
    reg buffer_full;
    reg output_valid;
    
    // 输入数据寄存器阶段
    reg [7:0] data_a_reg, data_b_reg, data_c_reg, data_d_reg;
    // 数据缓冲存储
    reg [7:0] buffer_stage [0:3];
    // 选择信号寄存器
    reg [1:0] select_reg;
    // Valid寄存器
    reg valid_in_reg;
    
    // 输出寄存器
    reg [7:0] data_out_reg;
    reg [1:0] output_select_reg;
    
    // 握手信号连接
    assign ready_in = !buffer_full || (output_valid && ready_out);
    assign valid_out = output_valid;
    assign data_out = data_out_reg;
    
    // 第一阶段：输入数据寄存 - 扁平化if-else结构
    always @(posedge clk) begin
        if (valid_in && ready_in) begin
            data_a_reg <= data_a;
            data_b_reg <= data_b;
            data_c_reg <= data_c;
            data_d_reg <= data_d;
            select_reg <= select;
            valid_in_reg <= 1'b1;
        end else if (ready_in && output_valid) begin
            valid_in_reg <= 1'b0;
        end
    end
    
    // 第二阶段：写入缓冲区 - 扁平化if-else结构
    always @(posedge clk) begin
        if (valid_in_reg && !buffer_full) begin
            if (select_reg == 2'b00) buffer_stage[0] <= data_a_reg;
            if (select_reg == 2'b01) buffer_stage[1] <= data_b_reg;
            if (select_reg == 2'b10) buffer_stage[2] <= data_c_reg;
            if (select_reg == 2'b11) buffer_stage[3] <= data_d_reg;
            output_select_reg <= select_reg;
            buffer_full <= 1'b1;
            valid_in_reg <= 1'b0;
        end else if (buffer_full && ready_out && output_valid) begin
            buffer_full <= 1'b0;
        end
    end
    
    // 最终阶段：输出控制 - 扁平化if-else结构
    always @(posedge clk) begin
        if (buffer_full && !output_valid) begin
            data_out_reg <= buffer_stage[output_select_reg];
            output_valid <= 1'b1;
        end else if (output_valid && ready_out) begin
            output_valid <= 1'b0;
        end
    end
    
    // 初始化
    initial begin
        buffer_full = 1'b0;
        output_valid = 1'b0;
        valid_in_reg = 1'b0;
    end
    
endmodule