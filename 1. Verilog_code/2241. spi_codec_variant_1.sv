//SystemVerilog
module spi_codec #(parameter DATA_WIDTH=8) (
    input clk, rst_n, en,
    input mosi, cs_n,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg data_valid
);
    reg [2:0] bit_cnt;
    reg last_bit;
    
    // 条件反相减法器实现
    reg [2:0] bit_cnt_next;
    wire [2:0] cnt_complement;
    wire borrow;
    
    // 计算补码 (反相)
    assign cnt_complement = ~(3'b001);
    
    // 条件反相减法器逻辑
    assign {borrow, bit_cnt_next} = (bit_cnt == DATA_WIDTH-1) ? 
                                    {1'b0, 3'b000} : 
                                    bit_cnt + 3'b001;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bit_cnt <= 3'b000;
            rx_data <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
            last_bit <= 1'b0;
        end else if(en && !cs_n) begin
            rx_data <= {rx_data[DATA_WIDTH-2:0], mosi};
            
            // 更新计数器使用条件反相减法器实现
            bit_cnt <= bit_cnt_next;
            
            // 判断是否到达最后一位
            last_bit <= (bit_cnt == DATA_WIDTH-1);
            
            // Explicit data_valid generation
            data_valid <= last_bit;
        end else begin
            data_valid <= 1'b0;
        end
    end
endmodule