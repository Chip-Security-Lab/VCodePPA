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
    // 流水线化的输入数据
    reg                  valid_in_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    
    // 状态寄存器
    reg [DATA_WIDTH-1:0] current_data;
    reg [DATA_WIDTH-1:0] run_count;
    
    // 注册输入信号，将寄存器向前移动
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_reg <= 1'b0;
            data_in_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            valid_in_reg <= valid_in;
            data_in_reg <= data_in;
        end
    end
    
    // 组合逻辑部分 - 计算下一状态和输出
    reg                  next_valid_out;
    reg [DATA_WIDTH-1:0] next_data_out;
    reg [DATA_WIDTH-1:0] next_count_out;
    reg [DATA_WIDTH-1:0] next_current_data;
    reg [DATA_WIDTH-1:0] next_run_count;
    
    always @(*) begin
        next_valid_out = 1'b0;
        next_data_out = data_out;
        next_count_out = count_out;
        next_current_data = current_data;
        next_run_count = run_count;
        
        if (valid_in_reg) begin
            if (data_in_reg == current_data && run_count < {DATA_WIDTH{1'b1}}) begin
                next_run_count = run_count + 1;
                next_valid_out = 1'b0;
            end else begin
                // 当检测到新字符或达到最大计数时输出
                next_valid_out = (run_count != 0);
                next_data_out = current_data;
                next_count_out = run_count;
                
                // 更新当前字符和计数
                next_current_data = data_in_reg;
                next_run_count = 1;
            end
        end
    end
    
    // 寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_data <= {DATA_WIDTH{1'b0}};
            run_count <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            count_out <= {DATA_WIDTH{1'b0}};
        end else begin
            // 更新状态寄存器
            current_data <= next_current_data;
            run_count <= next_run_count;
            
            // 更新输出寄存器
            valid_out <= next_valid_out;
            data_out <= next_data_out;
            count_out <= next_count_out;
        end
    end
endmodule