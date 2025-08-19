//SystemVerilog
module delta_encoder #(
    parameter WIDTH = 12
)(
    input                   clk_i,
    input                   en_i,
    input                   rst_i,
    input      [WIDTH-1:0]  data_i,
    output     [WIDTH-1:0]  delta_o,
    output                  valid_o
);
    // 寄存器声明
    reg [WIDTH-1:0] data_reg;
    reg [WIDTH-1:0] prev_sample;
    reg [WIDTH-1:0] delta_reg;
    reg             en_reg;
    reg             valid_reg;
    
    // 组合逻辑部分
    wire [WIDTH-1:0] delta_next;
    
    // 计算增量值的组合逻辑
    assign delta_next = data_reg - prev_sample;
    
    // 时序逻辑输出赋值
    assign delta_o = delta_reg;
    assign valid_o = valid_reg;
    
    // 输入寄存阶段 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            data_reg <= {WIDTH{1'b0}};
            en_reg <= 1'b0;
        end else begin
            data_reg <= data_i;
            en_reg <= en_i;
        end
    end
    
    // 处理阶段 - 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            prev_sample <= {WIDTH{1'b0}};
            delta_reg <= {WIDTH{1'b0}};
            valid_reg <= 1'b0;
        end else begin
            if (en_reg) begin
                delta_reg <= delta_next;
                prev_sample <= data_reg;
                valid_reg <= 1'b1;
            end else begin
                valid_reg <= 1'b0;
            end
        end
    end
endmodule