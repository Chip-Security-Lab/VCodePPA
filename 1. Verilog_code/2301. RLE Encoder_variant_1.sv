//SystemVerilog
module rle_encoder #(parameter DATA_WIDTH = 8) (
    input                       clk,
    input                       rst_n,
    input                       valid_in,
    input      [DATA_WIDTH-1:0] data_in,
    output reg                  valid_out,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [DATA_WIDTH-1:0] count_out
);
    reg [DATA_WIDTH-1:0] current_data;
    reg [DATA_WIDTH-1:0] run_count;
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg                  valid_in_reg;
    
    // 为高扇出信号run_count添加缓冲寄存器
    reg [DATA_WIDTH-1:0] run_count_buf1;
    reg [DATA_WIDTH-1:0] run_count_buf2;
    
    // 前向寄存器 - 保存输入值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
            valid_in_reg <= 0;
        end else begin
            data_in_reg <= data_in;
            valid_in_reg <= valid_in;
        end
    end
    
    // 缓冲寄存器更新 - 分担run_count的扇出负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            run_count_buf1 <= 0;
            run_count_buf2 <= 0;
        end else begin
            run_count_buf1 <= run_count;
            run_count_buf2 <= run_count;
        end
    end
    
    // 核心处理逻辑
    wire same_data = (data_in_reg == current_data);
    // 使用缓冲寄存器1用于比较操作
    wire count_not_max = (run_count_buf1 < {DATA_WIDTH{1'b1}});
    wire should_increment = same_data && count_not_max;
    // 使用缓冲寄存器2用于零值检测
    wire should_output = valid_in_reg && !should_increment && (run_count_buf2 != 0);
    wire valid_output_condition = (run_count_buf2 != 0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_data <= 0;
            run_count <= 0;
            valid_out <= 0;
            data_out <= 0;
            count_out <= 0;
        end else begin
            if (valid_in_reg) begin
                if (should_increment) begin
                    run_count <= run_count + 1;
                end else begin
                    data_out <= current_data;
                    count_out <= run_count;
                    valid_out <= valid_output_condition;
                    current_data <= data_in_reg;
                    run_count <= 1;
                end
            end else begin
                valid_out <= 0;
            end
        end
    end
endmodule