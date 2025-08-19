//SystemVerilog
module sync_rom (
    input wire clk,
    input wire rst_n,
    
    // 请求接口 - Valid/Ready协议
    input wire [3:0] addr,
    input wire addr_valid,
    output reg addr_ready,
    
    // 响应接口 - Valid/Ready协议
    output reg [7:0] data,
    output reg data_valid,
    input wire data_ready
);
    // ROM存储器定义
    reg [7:0] rom [0:15];
    
    // 存储请求状态
    reg request_pending;
    reg [3:0] pending_addr;
    
    // ROM初始化
    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
        rom[8] = 8'hAB; rom[9] = 8'hCD; rom[10] = 8'hEF; rom[11] = 8'h01;
        rom[12] = 8'h23; rom[13] = 8'h45; rom[14] = 8'h67; rom[15] = 8'h89;
    end

    // 地址输入处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_ready <= 1'b1;
            request_pending <= 1'b0;
            pending_addr <= 4'b0;
        end else begin
            // 默认状态
            addr_ready <= ~request_pending;
            
            // 接收新的地址请求
            if (addr_valid && addr_ready) begin
                pending_addr <= addr;
                request_pending <= 1'b1;
                addr_ready <= 1'b0;
            end
            
            // 当数据被接收后，可以接受新的请求
            if (data_valid && data_ready) begin
                request_pending <= 1'b0;
                addr_ready <= 1'b1;
            end
        end
    end

    // 数据输出处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
            data_valid <= 1'b0;
        end else begin
            // 当数据被接收后，取消有效标志
            if (data_valid && data_ready) begin
                data_valid <= 1'b0;
            end
            
            // 处理挂起的请求
            if (request_pending && !data_valid) begin
                data <= rom[pending_addr];
                data_valid <= 1'b1;
            end
        end
    end
endmodule