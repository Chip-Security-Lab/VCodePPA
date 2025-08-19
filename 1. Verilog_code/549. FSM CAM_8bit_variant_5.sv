//SystemVerilog
module cam_9 (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    output reg match_flag,
    output reg [7:0] stored_data
);
    // 状态定义
    localparam IDLE = 2'b00,
              COMPARE = 2'b01;
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [7:0] data_reg;
    wire compare_result;
    
    // Baugh-Wooley乘法器实现比较功能
    wire [7:0] diff;
    wire [7:0] abs_diff;
    wire [7:0] neg_diff;
    wire [7:0] pos_diff;
    
    // 计算差值
    assign diff = data_reg - data_in;
    
    // 计算绝对值
    assign neg_diff = ~diff + 1'b1;
    assign pos_diff = diff;
    assign abs_diff = diff[7] ? neg_diff : pos_diff;
    
    // 比较结果
    assign compare_result = (abs_diff == 8'b0);
    
    // 组合逻辑计算下一状态
    always @(*) begin
        if (state == IDLE) begin
            next_state = COMPARE;
        end else if (state == COMPARE) begin
            next_state = IDLE;
        end else begin
            next_state = IDLE;
        end
    end
    
    // 时序逻辑，分离数据存储和状态转换
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            stored_data <= 8'b0;
            match_flag <= 1'b0;
            data_reg <= 8'b0;
        end else begin
            // 数据寄存器更新
            data_reg <= data_in;
            
            // 状态转换逻辑
            state <= next_state;
            
            // 输出逻辑
            if (state == IDLE) begin
                stored_data <= data_reg;
            end else if (state == COMPARE) begin
                match_flag <= compare_result;
            end
        end
    end
endmodule