//SystemVerilog
module nibble_buffer (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] nibble_in,
    input  wire       valid_in,    // 替换原来的upper_en/lower_en信号
    input  wire       mode,        // 0:写入低位, 1:写入高位
    output wire [7:0] byte_out,
    output wire       valid_out,   // 数据有效标志
    input  wire       ready_out    // 下游准备接收数据
);
    // 内部状态和寄存器
    reg [7:0] byte_reg;
    reg       upper_loaded;
    reg       lower_loaded;
    reg       output_valid;
    
    // 数据加载逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_reg <= 8'h00;
            upper_loaded <= 1'b0;
            lower_loaded <= 1'b0;
        end else if (valid_in && ready_out) begin
            if (mode) begin
                // 写入高位
                byte_reg[7:4] <= nibble_in;
                upper_loaded <= 1'b1;
            end else begin
                // 写入低位
                byte_reg[3:0] <= nibble_in;
                lower_loaded <= 1'b1;
            end
        end else if (output_valid && ready_out) begin
            // 数据已被接收，重置状态
            upper_loaded <= 1'b0;
            lower_loaded <= 1'b0;
        end
    end
    
    // 输出有效信号控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid <= 1'b0;
        end else if (upper_loaded && lower_loaded) begin
            output_valid <= 1'b1;
        end else if (output_valid && ready_out) begin
            output_valid <= 1'b0;
        end
    end
    
    // 输出赋值
    assign byte_out = byte_reg;
    assign valid_out = output_valid;
    
endmodule