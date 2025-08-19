module cam_3 (
    input wire clk,
    input wire rst,         // 复位信号
    input wire write_en,    // 写入使能
    input wire [7:0] data_in,
    output wire match,      // 匹配信号
    output reg [7:0] stored_data
);
    // 内部比较输入预寄存器
    reg [7:0] data_in_reg;
    reg [7:0] stored_data_comp;
    
    // 匹配信号寄存器
    reg match_reg;
    
    // 实例化比较器
    comparator_3 comp (
        .a(stored_data_comp),
        .b(data_in_reg),
        .match(match)
    );
    
    // 将寄存器移动到组合逻辑前面
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= 8'b0;
            stored_data_comp <= 8'b0;
        end else begin
            data_in_reg <= data_in;
            stored_data_comp <= stored_data;
        end
    end
    
    // 添加复位和写入控制
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 8'b0;
        end else if (write_en) begin
            stored_data <= data_in;
        end
    end
endmodule

module comparator_3 (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire match
);
    assign match = (a == b);
endmodule