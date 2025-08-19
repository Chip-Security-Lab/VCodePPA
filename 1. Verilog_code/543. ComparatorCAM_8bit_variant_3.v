module cam_3 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] data_in,
    output wire match,
    output reg [7:0] stored_data
);
    // 实例化比较器
    comparator_3 comp (
        .a(stored_data),
        .b(data_in),
        .match(match)
    );
    
    // 添加复位和写入控制，使用if-else级联结构替代case语句
    always @(posedge clk) begin
        if (rst) begin
            stored_data <= 8'b0;      // 复位
        end else if (write_en) begin
            stored_data <= data_in;   // 写入
        end else begin
            stored_data <= stored_data; // 保持原值
        end
    end
endmodule

module comparator_3 (
    input wire [7:0] a,
    input wire [7:0] b,
    output reg match
);
    always @(*) begin
        match = (a == b);
    end
endmodule