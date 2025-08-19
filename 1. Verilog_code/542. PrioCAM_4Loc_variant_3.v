module cam_2 (
    input wire clk,
    input wire rst,
    
    // 写入接口（带Valid-Ready握手）
    input wire write_valid,     // 写请求有效信号
    output reg write_ready,     // 写就绪信号
    input wire [1:0] write_addr,
    input wire [7:0] write_data,
    
    // 查找接口（带Valid-Ready握手）
    input wire lookup_valid,    // 查找请求有效信号
    output reg lookup_ready,    // 查找就绪信号
    input wire [7:0] lookup_data,
    
    // 结果接口（带Valid-Ready握手）
    output reg result_valid,    // 结果有效信号
    input wire result_ready,    // 结果就绪信号
    output reg [3:0] cam_address
);
    // CAM存储内容
    reg [7:0] data0, data1, data2, data3;
    
    // 状态定义
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam LOOKUP = 2'b10;
    localparam RESULT = 2'b11;
    
    reg [1:0] state, next_state;
    reg [3:0] match_address;
    reg match_valid;
    
    // 状态转换逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 下一状态逻辑和输出控制
    always @(*) begin
        // 默认值
        write_ready = 1'b0;
        lookup_ready = 1'b0;
        result_valid = 1'b0;
        next_state = state;
        
        if (state == IDLE) begin
            // 写优先级高于查找
            if (write_valid) begin
                write_ready = 1'b1;
                next_state = WRITE;
            end else if (lookup_valid) begin
                lookup_ready = 1'b1;
                next_state = LOOKUP;
            end
        end else if (state == WRITE) begin
            // 写操作完成后返回空闲状态
            next_state = IDLE;
        end else if (state == LOOKUP) begin
            // 查找完成后进入结果状态
            next_state = RESULT;
        end else if (state == RESULT) begin
            // 结果有效，等待接收方准备好
            result_valid = 1'b1;
            if (result_ready) begin
                next_state = IDLE;
            end
        end
    end
    
    // 数据路径
    always @(posedge clk) begin
        if (rst) begin
            data0 <= 8'b0;
            data1 <= 8'b0;
            data2 <= 8'b0;
            data3 <= 8'b0;
            cam_address <= 4'h0;
            match_valid <= 1'b0;
            match_address <= 4'h0;
        end else begin
            if (state == IDLE) begin
                // 空闲状态不做任何数据操作
            end else if (state == WRITE) begin
                if (write_valid && write_ready) begin
                    if (write_addr == 2'b00) begin
                        data0 <= write_data;
                    end else if (write_addr == 2'b01) begin
                        data1 <= write_data;
                    end else if (write_addr == 2'b10) begin
                        data2 <= write_data;
                    end else if (write_addr == 2'b11) begin
                        data3 <= write_data;
                    end
                end
            end else if (state == LOOKUP) begin
                if (lookup_valid && lookup_ready) begin
                    // 优先级匹配逻辑
                    if (data0 == lookup_data) begin
                        match_address <= 4'h0;
                        match_valid <= 1'b1;
                    end else if (data1 == lookup_data) begin
                        match_address <= 4'h1;
                        match_valid <= 1'b1;
                    end else if (data2 == lookup_data) begin
                        match_address <= 4'h2;
                        match_valid <= 1'b1;
                    end else if (data3 == lookup_data) begin
                        match_address <= 4'h3;
                        match_valid <= 1'b1;
                    end else begin
                        match_valid <= 1'b0;
                        match_address <= 4'h0;
                    end
                end
            end else if (state == RESULT) begin
                if (result_valid && result_ready) begin
                    // 结果被接收，更新输出
                    cam_address <= match_address;
                    // 清除匹配状态，为下一次操作准备
                    match_valid <= 1'b0;
                end
            end
        end
    end
endmodule