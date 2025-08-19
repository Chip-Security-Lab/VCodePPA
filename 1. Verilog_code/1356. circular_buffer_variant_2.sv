//SystemVerilog
module circular_buffer (
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire write_en,
    input wire read_en,
    output reg [7:0] data_out,
    output reg empty,
    output reg full
);
    // Memory and pointer declarations
    reg [7:0] mem [0:3];
    reg [1:0] wr_ptr, rd_ptr;
    reg [2:0] count;
    
    // Fan-out buffer registers for control signals
    reg write_en_buf1, write_en_buf2;
    reg read_en_buf1, read_en_buf2;
    reg [2:0] count_buf1, count_buf2;
    
    // Buffer the high fan-out control signals
    always @(posedge clk) begin
        if (rst) begin
            write_en_buf1 <= 1'b0;
            write_en_buf2 <= 1'b0;
            read_en_buf1 <= 1'b0;
            read_en_buf2 <= 1'b0;
            count_buf1 <= 3'b000;
            count_buf2 <= 3'b000;
        end else begin
            write_en_buf1 <= write_en;
            write_en_buf2 <= write_en;
            read_en_buf1 <= read_en;
            read_en_buf2 <= read_en;
            count_buf1 <= count;
            count_buf2 <= count;
        end
    end
    
    // 指针和计数器更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 2'b00;
            rd_ptr <= 2'b00;
            count <= 3'b000;
        end else begin
            if (write_en_buf1 && !full && !read_en_buf1)
                count <= count + 1'b1;
            else if (read_en_buf1 && !empty && !write_en_buf1)
                count <= count - 1'b1;
                
            if (write_en_buf1 && !full)
                wr_ptr <= wr_ptr + 1'b1;
                
            if (read_en_buf1 && !empty)
                rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    // 内存写入逻辑
    always @(posedge clk) begin
        if (write_en_buf2 && !full)
            mem[wr_ptr] <= data_in;
    end
    
    // 数据输出逻辑
    always @(posedge clk) begin
        if (rst)
            data_out <= 8'h00;
        else if (read_en_buf2 && !empty)
            data_out <= mem[rd_ptr];
    end
    
    // 状态标志逻辑
    always @(posedge clk) begin
        if (rst) begin
            empty <= 1'b1;
            full <= 1'b0;
        end else begin
            empty <= (count_buf2 == 3'b000) || (read_en_buf2 && (count_buf2 == 3'b001) && !write_en_buf2);
            full <= (count_buf2 == 3'b100) || (write_en_buf2 && (count_buf2 == 3'b011) && !read_en_buf2);
        end
    end
    
endmodule