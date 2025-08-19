//SystemVerilog
module spi_codec #(parameter DATA_WIDTH=8) (
    input clk, rst_n, en,
    input mosi, cs_n,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg data_valid
);
    reg [2:0] bit_cnt;
    wire [2:0] next_bit_cnt;
    reg [2:0] target_count_reg;
    wire [2:0] target_count;
    
    // 寄存高扇出信号
    reg [2:0] bit_cnt_buf1, bit_cnt_buf2;
    reg [2:0] target_count_buf1, target_count_buf2;
    reg [2:0] incremented_cnt_reg;
    reg carry1_reg1, carry1_reg2;
    
    // 目标计数值
    assign target_count = DATA_WIDTH-1;
    
    // 将高扇出信号寄存，分散驱动负载
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bit_cnt_buf1 <= 3'b000;
            bit_cnt_buf2 <= 3'b000;
            target_count_reg <= 3'b000;
            target_count_buf1 <= 3'b000;
            target_count_buf2 <= 3'b000;
        end else begin
            target_count_reg <= target_count;
            target_count_buf1 <= target_count_reg;
            target_count_buf2 <= target_count_buf1;
            bit_cnt_buf1 <= bit_cnt;
            bit_cnt_buf2 <= bit_cnt_buf1;
        end
    end
    
    // 借位减法器实现 - 分散借位计算以减轻路径负载
    wire borrow_1, borrow_2, borrow_3;
    assign borrow_1 = (bit_cnt_buf1[0] < target_count_buf1[0]);
    assign borrow_2 = ((bit_cnt_buf1[1] < target_count_buf1[1]) || 
                      ((bit_cnt_buf1[1] == target_count_buf1[1]) && borrow_1));
    assign borrow_3 = ((bit_cnt_buf2[2] < target_count_buf2[2]) || 
                      ((bit_cnt_buf2[2] == target_count_buf2[2]) && borrow_2));
    
    // 判断是否等于目标值
    wire is_target_count = ~borrow_3;
    
    // 位计数器增加逻辑 - 分散扇出
    wire [2:0] incremented_cnt;
    wire carry1, carry2;
    
    assign carry1 = bit_cnt[0];
    
    // 寄存高扇出信号carry1
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            carry1_reg1 <= 1'b0;
            carry1_reg2 <= 1'b0;
            incremented_cnt_reg <= 3'b000;
        end else begin
            carry1_reg1 <= carry1;
            carry1_reg2 <= carry1_reg1;
            incremented_cnt_reg <= incremented_cnt;
        end
    end
    
    assign incremented_cnt[0] = ~bit_cnt[0];
    assign carry2 = carry1_reg1 & bit_cnt[1];
    assign incremented_cnt[1] = bit_cnt[1] ^ carry1_reg1;
    assign incremented_cnt[2] = bit_cnt[2] ^ carry2;
    
    // 选择下一个计数值
    assign next_bit_cnt = is_target_count ? 3'b000 : incremented_cnt_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bit_cnt <= 3'b000;
            rx_data <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else if(en && !cs_n) begin
            rx_data <= {rx_data[DATA_WIDTH-2:0], mosi};
            bit_cnt <= next_bit_cnt;
            data_valid <= is_target_count;
        end
    end
endmodule