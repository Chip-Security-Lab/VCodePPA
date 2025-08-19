//SystemVerilog
module sync_decoder_valid_ready (
    // 全局信号
    input wire clk,
    input wire rst_n,
    
    // 写请求通道 - Valid-Ready握手
    input wire [31:0] write_addr,
    input wire [2:0] write_prot,
    input wire [31:0] write_data,
    input wire [3:0] write_strb,
    input wire write_valid,
    output reg write_ready,
    
    // 写响应通道 - Valid-Ready握手
    output reg [1:0] write_resp,
    output reg write_resp_valid,
    input wire write_resp_ready,
    
    // 读请求通道 - Valid-Ready握手
    input wire [31:0] read_addr,
    input wire [2:0] read_prot,
    input wire read_valid,
    output reg read_ready,
    
    // 读响应通道 - Valid-Ready握手
    output reg [31:0] read_data,
    output reg [1:0] read_resp,
    output reg read_resp_valid,
    input wire read_resp_ready,
    
    // 解码器输出
    output wire [7:0] decode_out
);

    // 内部寄存器
    reg [2:0] address_reg;
    reg [7:0] decode_out_reg;
    
    // 状态机状态定义
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam RESPONSE = 2'b10;
    
    // 状态寄存器
    reg [1:0] write_state;
    reg [1:0] read_state;
    
    // 寄存器地址
    localparam ADDR_DECODER = 4'h0;
    
    // 写状态机 - 使用Valid-Ready握手
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= IDLE;
            write_ready <= 1'b0;
            write_resp <= 2'b00;
            write_resp_valid <= 1'b0;
        end else begin
            case (write_state)
                IDLE: begin
                    // 准备接收新的写请求
                    write_ready <= 1'b1;
                    
                    if (write_valid && write_ready) begin
                        // 握手成功，处理写请求
                        write_ready <= 1'b0;
                        write_state <= PROCESS;
                        
                        // 只接受特定地址的写操作
                        if (write_addr[3:0] == ADDR_DECODER) begin
                            if (write_strb[0]) begin
                                address_reg <= write_data[2:0];
                            end
                            write_resp <= 2'b00; // OKAY
                        end else begin
                            write_resp <= 2'b10; // SLVERR - 不支持的地址
                        end
                    end
                end
                
                PROCESS: begin
                    // 处理完成，准备发送响应
                    write_resp_valid <= 1'b1;
                    write_state <= RESPONSE;
                end
                
                RESPONSE: begin
                    // 等待响应被接收
                    if (write_resp_valid && write_resp_ready) begin
                        write_resp_valid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: begin
                    write_state <= IDLE;
                end
            endcase
        end
    end
    
    // 读状态机 - 使用Valid-Ready握手
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= IDLE;
            read_ready <= 1'b0;
            read_data <= 32'h0;
            read_resp <= 2'b00;
            read_resp_valid <= 1'b0;
        end else begin
            case (read_state)
                IDLE: begin
                    // 准备接收新的读请求
                    read_ready <= 1'b1;
                    
                    if (read_valid && read_ready) begin
                        // 握手成功，处理读请求
                        read_ready <= 1'b0;
                        read_state <= PROCESS;
                    end
                end
                
                PROCESS: begin
                    // 准备数据
                    if (read_addr[3:0] == ADDR_DECODER) begin
                        read_data <= {24'h0, decode_out_reg};
                        read_resp <= 2'b00; // OKAY
                    end else begin
                        read_data <= 32'h0;
                        read_resp <= 2'b10; // SLVERR - 不支持的地址
                    end
                    
                    // 设置响应有效
                    read_resp_valid <= 1'b1;
                    read_state <= RESPONSE;
                end
                
                RESPONSE: begin
                    // 等待响应被接收
                    if (read_resp_valid && read_resp_ready) begin
                        read_resp_valid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end
    
    // 核心解码器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_out_reg <= 8'b0;
        else
            decode_out_reg <= (8'b1 << address_reg);
    end
    
    // 输出赋值
    assign decode_out = decode_out_reg;

endmodule