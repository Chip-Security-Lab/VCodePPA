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
    output [DATA_WIDTH-1:0] pixel_out,
    output [7:0] rd_x, rd_y,
    output frame_start, line_start
);
    localparam ADDR_WIDTH = $clog2(WIDTH * HEIGHT);
    
    // 内部信号声明
    wire [ADDR_WIDTH-1:0] write_addr;
    wire [DATA_WIDTH-1:0] read_data_buf0, read_data_buf1, read_data_buf2;
    wire [DATA_WIDTH-1:0] selected_pixel;
    wire next_line, next_frame;
    wire [7:0] next_rd_x, next_rd_y;
    wire next_line_start, next_frame_start;
    wire [1:0] next_read_buf, next_write_buf, next_display_buf;
    
    // 寄存器信号声明
    reg [1:0] write_buf, read_buf, display_buf;
    reg [7:0] rd_x_reg, rd_y_reg;
    reg frame_start_reg, line_start_reg;
    reg [DATA_WIDTH-1:0] pixel_out_reg;
    
    // 三个缓冲区存储器
    reg [DATA_WIDTH-1:0] buffer0 [0:WIDTH*HEIGHT-1];
    reg [DATA_WIDTH-1:0] buffer1 [0:WIDTH*HEIGHT-1];
    reg [DATA_WIDTH-1:0] buffer2 [0:WIDTH*HEIGHT-1];
    
    // 组合逻辑部分
    addr_calculator addr_calc (
        .wr_x(wr_x),
        .wr_y(wr_y),
        .width(WIDTH),
        .write_addr(write_addr)
    );
    
    buffer_reader buf_reader (
        .rd_x(rd_x_reg),
        .rd_y(rd_y_reg),
        .width(WIDTH),
        .buffer0_data(buffer0),
        .buffer1_data(buffer1),
        .buffer2_data(buffer2),
        .read_data_buf0(read_data_buf0),
        .read_data_buf1(read_data_buf1),
        .read_data_buf2(read_data_buf2)
    );
    
    scan_controller scan_ctrl (
        .rd_x(rd_x_reg),
        .rd_y(rd_y_reg),
        .width(WIDTH),
        .height(HEIGHT),
        .next_line(next_line),
        .next_frame(next_frame),
        .next_rd_x(next_rd_x),
        .next_rd_y(next_rd_y)
    );
    
    buffer_controller buf_ctrl (
        .buffer_swap(buffer_swap),
        .rd_en(rd_en),
        .read_buf(read_buf),
        .write_buf(write_buf),
        .display_buf(display_buf),
        .read_data_buf0(read_data_buf0),
        .read_data_buf1(read_data_buf1),
        .read_data_buf2(read_data_buf2),
        .next_line(next_line),
        .next_frame(next_frame),
        .next_read_buf(next_read_buf),
        .next_write_buf(next_write_buf),
        .next_display_buf(next_display_buf),
        .next_line_start(next_line_start),
        .next_frame_start(next_frame_start),
        .selected_pixel(selected_pixel)
    );
    
    // 输出赋值
    assign rd_x = rd_x_reg;
    assign rd_y = rd_y_reg;
    assign frame_start = frame_start_reg;
    assign line_start = line_start_reg;
    assign pixel_out = pixel_out_reg;
    
    // 写入缓冲区 - 时序逻辑
    always @(posedge clk) begin
        if (wr_en) begin
            case (write_buf)
                2'b00: buffer0[write_addr] <= pixel_in;
                2'b01: buffer1[write_addr] <= pixel_in;
                2'b10: buffer2[write_addr] <= pixel_in;
                default: ; // 无效状态不做操作
            endcase
        end
    end
    
    // 主状态更新 - 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_buf <= 2'b00;
            write_buf <= 2'b01;
            display_buf <= 2'b10;
            rd_x_reg <= 8'd0;
            rd_y_reg <= 8'd0;
            frame_start_reg <= 1'b0;
            line_start_reg <= 1'b0;
            pixel_out_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            // 更新状态
            if (buffer_swap || rd_en) begin
                read_buf <= next_read_buf;
                write_buf <= next_write_buf;
                display_buf <= next_display_buf;
                rd_x_reg <= next_rd_x;
                rd_y_reg <= next_rd_y;
                frame_start_reg <= next_frame_start;
                line_start_reg <= next_line_start;
                
                if (rd_en) begin
                    pixel_out_reg <= selected_pixel;
                end
            end else begin
                // 默认行为
                frame_start_reg <= 1'b0;
                line_start_reg <= 1'b0;
            end
        end
    end
endmodule

// 地址计算器模块 - 纯组合逻辑
module addr_calculator (
    input [7:0] wr_x, wr_y,
    input [15:0] width,
    output [$clog2(16*16)-1:0] write_addr
);
    assign write_addr = wr_y * width + wr_x;
endmodule

// 缓冲区读取模块 - 纯组合逻辑
module buffer_reader (
    input [7:0] rd_x, rd_y,
    input [15:0] width,
    input [15:0] buffer0_data [0:16*16-1],
    input [15:0] buffer1_data [0:16*16-1],
    input [15:0] buffer2_data [0:16*16-1],
    output [15:0] read_data_buf0, read_data_buf1, read_data_buf2
);
    wire [$clog2(16*16)-1:0] read_addr;
    
    assign read_addr = rd_y * width + rd_x;
    assign read_data_buf0 = buffer0_data[read_addr];
    assign read_data_buf1 = buffer1_data[read_addr];
    assign read_data_buf2 = buffer2_data[read_addr];
endmodule

// 扫描控制器模块 - 纯组合逻辑
module scan_controller (
    input [7:0] rd_x, rd_y,
    input [15:0] width, height,
    output next_line, next_frame,
    output [7:0] next_rd_x, next_rd_y
);
    // 计算下一行和下一帧标志
    assign next_line = (rd_x == width-1);
    assign next_frame = next_line && (rd_y == height-1);
    
    // 计算下一个坐标
    assign next_rd_x = next_line ? 8'd0 : rd_x + 8'd1;
    assign next_rd_y = next_line ? (next_frame ? 8'd0 : rd_y + 8'd1) : rd_y;
endmodule

// 缓冲区控制器模块 - 纯组合逻辑
module buffer_controller (
    input buffer_swap, rd_en,
    input [1:0] read_buf, write_buf, display_buf,
    input [15:0] read_data_buf0, read_data_buf1, read_data_buf2,
    input next_line, next_frame,
    output [1:0] next_read_buf, next_write_buf, next_display_buf,
    output next_line_start, next_frame_start,
    output [15:0] selected_pixel
);
    // 缓冲区切换逻辑
    assign next_read_buf = buffer_swap ? display_buf : read_buf;
    assign next_write_buf = buffer_swap ? read_buf : write_buf;
    assign next_display_buf = buffer_swap ? write_buf : display_buf;
    
    // 像素选择逻辑
    assign selected_pixel = (read_buf == 2'b00) ? read_data_buf0 :
                           (read_buf == 2'b01) ? read_data_buf1 :
                           (read_buf == 2'b10) ? read_data_buf2 :
                           16'h0000; // 无效状态返回0
    
    // 控制标志生成逻辑
    assign next_frame_start = buffer_swap || (rd_en && next_frame);
    assign next_line_start = buffer_swap || (rd_en && (next_line || next_frame));
endmodule