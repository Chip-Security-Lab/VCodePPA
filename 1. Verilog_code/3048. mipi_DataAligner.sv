module MIPI_DataAligner #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 32
)(
    input wire in_clk,
    input wire out_clk,
    input wire rst_n,
    input wire [IN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [OUT_WIDTH-1:0] dout,
    output wire dout_valid
);
    reg [OUT_WIDTH-1:0] buffer;
    reg [3:0] fill_level;
    reg buffer_full;
    
    // 写入FIFO寄存器
    reg [OUT_WIDTH-1:0] fifo_data [0:3];
    reg [1:0] wr_ptr;
    reg [1:0] rd_ptr;
    reg [2:0] fifo_count;
    
    // 写入侧逻辑
    always @(posedge in_clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer <= {OUT_WIDTH{1'b0}};
            fill_level <= 4'd0;
            buffer_full <= 1'b0;
            wr_ptr <= 2'd0;
            fifo_count <= 3'd0;
        end else if (din_valid) begin
            // 移位寄存器实现
            if (fill_level + IN_WIDTH >= OUT_WIDTH) begin
                // 缓冲区将满，写入FIFO
                fifo_data[wr_ptr] <= {din, buffer[OUT_WIDTH-1:IN_WIDTH]};
                buffer <= {buffer[IN_WIDTH-1:0], din};
                fill_level <= fill_level + IN_WIDTH - OUT_WIDTH;
                
                if (fifo_count < 4) begin
                    wr_ptr <= wr_ptr + 1;
                    fifo_count <= fifo_count + 1;
                end
            end else begin
                // 累积数据
                buffer <= {buffer[OUT_WIDTH-IN_WIDTH-1:0], din};
                fill_level <= fill_level + IN_WIDTH;
            end
        end
    end
    
    // 读出侧逻辑
    reg rd_valid;
    reg [OUT_WIDTH-1:0] rd_data;
    
    always @(posedge out_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 2'd0;
            rd_valid <= 1'b0;
            rd_data <= {OUT_WIDTH{1'b0}};
        end else begin
            rd_valid <= 1'b0;
            
            if (fifo_count > 0) begin
                rd_data <= fifo_data[rd_ptr];
                rd_valid <= 1'b1;
                rd_ptr <= rd_ptr + 1;
                fifo_count <= fifo_count - 1;
            end
        end
    end
    
    // 输出赋值
    assign dout = rd_data;
    assign dout_valid = rd_valid;
endmodule