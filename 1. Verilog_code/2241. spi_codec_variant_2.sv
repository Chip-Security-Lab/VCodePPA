//SystemVerilog
module spi_codec #(parameter DATA_WIDTH=8) (
    input clk, rst_n, en,
    input mosi, cs_n,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg data_valid
);
    // 内部信号
    reg [2:0] bit_cnt;
    reg byte_complete;
    
    // 前级寄存器，用于捕获输入
    reg mosi_r, cs_n_r, en_r;
    
    // 输入捕获寄存器 - 将寄存器前移到输入端
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mosi_r <= 1'b0;
            cs_n_r <= 1'b1;
            en_r <= 1'b0;
        end else begin
            mosi_r <= mosi;
            cs_n_r <= cs_n;
            en_r <= en;
        end
    end
    
    // 位计数器逻辑 - 使用前级寄存器的输入
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bit_cnt <= 3'b000;
        end else if(en_r && !cs_n_r) begin
            // 条件求和减法算法实现的计数器
            if(bit_cnt == DATA_WIDTH-1) begin
                bit_cnt <= 3'b000;
            end else begin
                bit_cnt[0] <= ~bit_cnt[0];
                bit_cnt[1] <= bit_cnt[1] ^ bit_cnt[0];
                bit_cnt[2] <= bit_cnt[2] ^ (bit_cnt[1] & bit_cnt[0]);
            end
        end
    end
    
    // 字节完成检测逻辑 - 使用前级寄存器的输入
    wire byte_complete_next = (bit_cnt == DATA_WIDTH-1) && en_r && !cs_n_r;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            byte_complete <= 1'b0;
        end else begin
            byte_complete <= byte_complete_next;
        end
    end
    
    // 数据移位寄存器逻辑 - 使用前级寄存器的输入
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rx_data <= {DATA_WIDTH{1'b0}};
        end else if(en_r && !cs_n_r) begin
            rx_data <= {rx_data[DATA_WIDTH-2:0], mosi_r};
        end
    end
    
    // 数据有效标志逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_valid <= 1'b0;
        end else begin
            data_valid <= byte_complete;
        end
    end
    
endmodule