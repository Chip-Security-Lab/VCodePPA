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
    // 寄存器信号
    reg                  valid_in_r;
    reg [DATA_WIDTH-1:0] data_in_r;
    reg [DATA_WIDTH-1:0] current_data;
    reg [DATA_WIDTH-1:0] run_count;
    
    // 组合逻辑信号
    wire                  update_required;
    wire [DATA_WIDTH-1:0] next_run_count;
    wire                  valid_out_next;
    wire [DATA_WIDTH-1:0] data_out_next;
    wire [DATA_WIDTH-1:0] count_out_next;
    
    // ==================== 组合逻辑部分 ====================
    // 计算更新条件和下一个计数值
    assign update_required = (data_in_r != current_data) || (run_count == {DATA_WIDTH{1'b1}});
    assign next_run_count = update_required ? 1'b1 : (run_count + 1'b1);
    
    // 计算输出有效信号
    assign valid_out_next = valid_in_r & update_required & (run_count != 0);
    
    // 计算下一个输出数据和计数值
    assign data_out_next = current_data;
    assign count_out_next = run_count;
    
    // ==================== 时序逻辑部分 ====================
    // 输入数据寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_r <= 1'b0;
            data_in_r <= {DATA_WIDTH{1'b0}};
        end else begin
            valid_in_r <= valid_in;
            data_in_r <= data_in;
        end
    end
    
    // 状态更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_data <= {DATA_WIDTH{1'b0}};
            run_count <= {DATA_WIDTH{1'b0}};
        end else if (valid_in_r) begin
            if (update_required) begin
                current_data <= data_in_r;
                run_count <= next_run_count;
            end else begin
                run_count <= next_run_count;
            end
        end
    end
    
    // 输出寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            count_out <= {DATA_WIDTH{1'b0}};
        end else begin
            // 输出有效信号控制
            if (!valid_in_r) begin
                valid_out <= 1'b0;
            end else begin
                valid_out <= valid_out_next;
            end
            
            // 输出数据更新
            if (valid_in_r && update_required) begin
                data_out <= data_out_next;
                count_out <= count_out_next;
            end
        end
    end
    
endmodule