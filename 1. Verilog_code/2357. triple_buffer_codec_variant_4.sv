//SystemVerilog
module triple_buffer_codec #(
    parameter WIDTH = 16,
    parameter HEIGHT = 16,
    parameter DATA_WIDTH = 16
) (
    input clk, rst_n,
    input [DATA_WIDTH-1:0] pixel_in,
    input wr_en,
    input [7:0] wr_x, wr_y,
    input buffer_swap,
    input rd_en,
    output reg [DATA_WIDTH-1:0] pixel_out,
    output reg [7:0] rd_x, rd_y,
    output reg frame_start, line_start
);
    localparam ADDR_WIDTH = $clog2(WIDTH * HEIGHT);
    
    // Triple buffer memory and control
    reg [DATA_WIDTH-1:0] buffer0 [0:WIDTH*HEIGHT-1];
    reg [DATA_WIDTH-1:0] buffer1 [0:WIDTH*HEIGHT-1];
    reg [DATA_WIDTH-1:0] buffer2 [0:WIDTH*HEIGHT-1];
    
    reg [1:0] write_buf, read_buf, display_buf;
    
    // 前向寄存器重定时：存储输入信号
    reg [7:0] wr_x_reg, wr_y_reg;
    reg [DATA_WIDTH-1:0] pixel_in_reg;
    reg wr_en_reg;
    reg buffer_swap_reg;
    reg rd_en_reg;
    
    // 向前移动寄存器，捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_x_reg <= 8'b0;
            wr_y_reg <= 8'b0;
            pixel_in_reg <= {DATA_WIDTH{1'b0}};
            wr_en_reg <= 1'b0;
            buffer_swap_reg <= 1'b0;
            rd_en_reg <= 1'b0;
        end else begin
            wr_x_reg <= wr_x;
            wr_y_reg <= wr_y;
            pixel_in_reg <= pixel_in;
            wr_en_reg <= wr_en;
            buffer_swap_reg <= buffer_swap;
            rd_en_reg <= rd_en;
        end
    end
    
    // Write address calculation - 使用寄存器后的信号
    wire [ADDR_WIDTH-1:0] write_addr = wr_y_reg * WIDTH + wr_x_reg;
    
    // Write operation - 使用寄存器后的信号
    always @(posedge clk) begin
        if (wr_en_reg) begin
            case (write_buf)
                2'b00: buffer0[write_addr] <= pixel_in_reg;
                2'b01: buffer1[write_addr] <= pixel_in_reg;
                2'b10: buffer2[write_addr] <= pixel_in_reg;
            endcase
        end
    end
    
    // Coordinate tracking registers and next-state logic
    reg [7:0] next_rd_x, next_rd_y;
    reg next_frame_start, next_line_start;
    
    // Pre-compute the read address
    wire [ADDR_WIDTH-1:0] read_addr = rd_y * WIDTH + rd_x;
    
    // 使用寄存器后的信号计算下一个坐标和控制信号
    always @(*) begin
        next_frame_start = frame_start;
        next_line_start = line_start;
        next_rd_x = rd_x;
        next_rd_y = rd_y;
        
        if (buffer_swap_reg) begin
            next_rd_x = 8'd0;
            next_rd_y = 8'd0;
            next_frame_start = 1'b1;
            next_line_start = 1'b1;
        end else if (rd_en_reg) begin
            next_frame_start = 1'b0;
            
            if (rd_x == WIDTH-1) begin
                next_rd_x = 8'd0;
                next_line_start = 1'b1;
                if (rd_y == HEIGHT-1)
                    next_rd_y = 8'd0;
                else
                    next_rd_y = rd_y + 8'd1;
            end else begin
                next_rd_x = rd_x + 8'd1;
                next_line_start = 1'b0;
            end
        end else begin
            next_frame_start = 1'b0;
            next_line_start = 1'b0;
        end
    end
    
    // 像素数据预读取和输出
    reg [DATA_WIDTH-1:0] pre_pixel_out;
    
    // 前向重定时：先读取内存数据
    always @(*) begin
        case (read_buf)
            2'b00: pre_pixel_out = buffer0[read_addr];
            2'b01: pre_pixel_out = buffer1[read_addr];
            2'b10: pre_pixel_out = buffer2[read_addr];
            default: pre_pixel_out = {DATA_WIDTH{1'b0}};
        endcase
    end
    
    // Buffer control and output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_buf <= 2'b00;
            write_buf <= 2'b01;
            display_buf <= 2'b10;
            rd_x <= 8'd0;
            rd_y <= 8'd0;
            frame_start <= 1'b0;
            line_start <= 1'b0;
            pixel_out <= {DATA_WIDTH{1'b0}};
        end else begin
            // Update coordinates and flags
            rd_x <= next_rd_x;
            rd_y <= next_rd_y;
            frame_start <= next_frame_start;
            line_start <= next_line_start;
            
            // Register pixel output
            if (rd_en_reg) begin
                pixel_out <= pre_pixel_out;
            end
            
            // Handle buffer swapping - 使用寄存器后的信号
            if (buffer_swap_reg) begin
                // Rotate buffers
                read_buf <= display_buf;
                display_buf <= write_buf;
                write_buf <= read_buf;
            end
        end
    end
endmodule