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
    reg [ADDR_WIDTH-1:0] write_addr, read_addr;
    
    // 优化的乘法实现: 使用位移和加法代替复杂乘法电路
    function [15:0] optimized_mult;
        input [7:0] multiplicand;
        input [7:0] multiplier;
        reg [15:0] result;
        reg [15:0] temp_result [0:7];
        integer i;
        begin
            result = 16'd0;
            
            for (i = 0; i < 8; i = i + 1) begin
                temp_result[i] = multiplier[i] ? (multiplicand << i) : 16'd0;
                result = result + temp_result[i];
            end
            
            optimized_mult = result;
        end
    endfunction
    
    // 计算地址 - 使用WIDTH的常量特性优化
    // 当WIDTH是2的幂时，可以用位移代替乘法
    wire [15:0] addr_mult_wr;
    wire [15:0] addr_mult_rd;
    
    generate
        if ((WIDTH & (WIDTH-1)) == 0) begin: power_of_two_addr
            // WIDTH是2的幂，使用位移
            localparam SHIFT_AMT = $clog2(WIDTH);
            assign addr_mult_wr = {wr_y, {SHIFT_AMT{1'b0}}};
            assign addr_mult_rd = {rd_y, {SHIFT_AMT{1'b0}}};
        end else begin: general_addr
            // 一般情况，使用优化的乘法
            assign addr_mult_wr = optimized_mult(WIDTH[7:0], wr_y);
            assign addr_mult_rd = optimized_mult(WIDTH[7:0], rd_y);
        end
    endgenerate
    
    // 地址计算逻辑
    always @(*) begin
        write_addr = addr_mult_wr[ADDR_WIDTH-1:0] + wr_x;
    end
    
    // 缓冲区选择逻辑
    reg [DATA_WIDTH-1:0] read_data;
    always @(*) begin
        case (read_buf)
            2'b00: read_data = buffer0[read_addr];
            2'b01: read_data = buffer1[read_addr];
            2'b10: read_data = buffer2[read_addr];
            default: read_data = {DATA_WIDTH{1'b0}};
        endcase
    end
    
    // Write operation - 单独时序块提高可综合性
    always @(posedge clk) begin
        if (wr_en) begin
            case (write_buf)
                2'b00: buffer0[write_addr] <= pixel_in;
                2'b01: buffer1[write_addr] <= pixel_in;
                2'b10: buffer2[write_addr] <= pixel_in;
                default: ; // 防止锁存器
            endcase
        end
    end
    
    // 边界检测逻辑优化
    wire x_at_end, y_at_end;
    assign x_at_end = (rd_x == WIDTH-1);
    assign y_at_end = (rd_y == HEIGHT-1);
    
    // Read operation and scan-out control
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
            read_addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (buffer_swap) begin
                // 简化的缓冲区旋转逻辑
                {read_buf, display_buf, write_buf} <= {display_buf, write_buf, read_buf};
                
                // Reset scan coordinates
                rd_x <= 8'd0;
                rd_y <= 8'd0;
                frame_start <= 1'b1;
                line_start <= 1'b1;
            end else if (rd_en) begin
                // 先计算读地址然后更新坐标
                read_addr <= addr_mult_rd[ADDR_WIDTH-1:0] + rd_x;
                pixel_out <= read_data;
                
                // 更新扫描坐标 - 使用预计算的边界条件
                frame_start <= 1'b0;
                
                if (x_at_end) begin
                    rd_x <= 8'd0;
                    line_start <= 1'b1;
                    rd_y <= y_at_end ? 8'd0 : (rd_y + 8'd1);
                end else begin
                    rd_x <= rd_x + 8'd1;
                    line_start <= 1'b0;
                end
            end else begin
                frame_start <= 1'b0;
                line_start <= 1'b0;
            end
        end
    end
endmodule