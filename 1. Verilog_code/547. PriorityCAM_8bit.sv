module cam_7 (
    input wire clk,
    input wire rst,         // 添加复位信号
    input wire write_en,    // 添加写入使能
    input wire write_high,  // 写入高优先级
    input wire [7:0] data_in,
    output reg match,
    output reg [7:0] priority_data
);
    reg [7:0] high_priority, low_priority;
    
    // 添加复位和写入控制
    always @(posedge clk) begin
        if (rst) begin
            high_priority <= 8'b0;
            low_priority <= 8'b0;
            match <= 1'b0;
            priority_data <= 8'b0;
        end else if (write_en) begin
            if (write_high)
                high_priority <= data_in;
            else
                low_priority <= data_in;
        end else begin
            if (high_priority == data_in) begin
                priority_data <= high_priority;
                match <= 1'b1;
            end else if (low_priority == data_in) begin
                priority_data <= low_priority;
                match <= 1'b1;
            end else begin
                match <= 1'b0;
            end
        end
    end
endmodule