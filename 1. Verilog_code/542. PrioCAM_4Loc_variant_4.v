module cam_2 (
    input wire clk,
    input wire rst,         
    input wire write_en,    
    input wire [1:0] write_addr, 
    input wire [7:0] in_data,
    output reg [3:0] cam_address,
    output reg cam_valid
);

    reg [7:0] data0, data1, data2, data3;
    
    // Buffer registers for high fanout signals
    reg [7:0] in_data_buf1, in_data_buf2;
    reg write_en_buf1, write_en_buf2;
    reg [1:0] write_addr_buf1, write_addr_buf2;
    reg rst_buf1, rst_buf2;
    
    // Buffer input signals to reduce fanout
    always @(posedge clk) begin
        // First stage buffers
        in_data_buf1 <= in_data;
        write_en_buf1 <= write_en;
        write_addr_buf1 <= write_addr;
        rst_buf1 <= rst;
        
        // Second stage buffers
        in_data_buf2 <= in_data_buf1;
        write_en_buf2 <= write_en_buf1;
        write_addr_buf2 <= write_addr_buf1;
        rst_buf2 <= rst_buf1;
    end

    // 复位和写入逻辑 - 使用缓冲信号
    always @(posedge clk) begin
        if (rst_buf1) begin
            reset_registers();
        end else if (write_en_buf1) begin
            write_data(write_addr_buf1, in_data_buf1);
        end
    end

    // 优先级匹配逻辑 - 使用缓冲信号
    always @(posedge clk) begin
        match_priority(in_data_buf2);
    end

    // 复位寄存器
    task reset_registers;
        begin
            data0 <= 8'b0;
            data1 <= 8'b0;
            data2 <= 8'b0;
            data3 <= 8'b0;
            cam_address <= 4'h0;
            cam_valid <= 1'b0;
        end
    endtask

    // 写入数据
    task write_data(input [1:0] addr, input [7:0] data);
        begin
            case (addr)
                2'b00: data0 <= data;
                2'b01: data1 <= data;
                2'b10: data2 <= data;
                2'b11: data3 <= data;
            endcase
        end
    endtask

    // 匹配优先级逻辑优化，使用中间信号分解比较操作
    reg match0, match1, match2, match3;
    
    // 预计算匹配结果，减少关键路径
    always @(posedge clk) begin
        match0 <= (data0 == in_data_buf1);
        match1 <= (data1 == in_data_buf1);
        match2 <= (data2 == in_data_buf1);
        match3 <= (data3 == in_data_buf1);
    end
    
    // 匹配优先级
    task match_priority(input [7:0] data);
        begin
            if (match0) begin
                cam_address <= 4'h0;
                cam_valid <= 1'b1;
            end else if (match1) begin
                cam_address <= 4'h1;
                cam_valid <= 1'b1;
            end else if (match2) begin
                cam_address <= 4'h2;
                cam_valid <= 1'b1;
            end else if (match3) begin
                cam_address <= 4'h3;
                cam_valid <= 1'b1;
            end else begin
                cam_valid <= 1'b0;
                cam_address <= 4'h0;
            end
        end
    endtask

endmodule