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
    
    // Write address calculation
    always @(*) begin
        write_addr = wr_y * WIDTH + wr_x;
    end
    
    // Write operation
    always @(posedge clk) begin
        if (wr_en) begin
            case (write_buf)
                2'b00: buffer0[write_addr] <= pixel_in;
                2'b01: buffer1[write_addr] <= pixel_in;
                2'b10: buffer2[write_addr] <= pixel_in;
            endcase
        end
    end
    
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
        end else begin
            if (buffer_swap) begin
                // Rotate buffers
                read_buf <= display_buf;
                display_buf <= write_buf;
                write_buf <= read_buf;
                
                // Reset scan coordinates
                rd_x <= 8'd0;
                rd_y <= 8'd0;
                frame_start <= 1'b1;
                line_start <= 1'b1;
            end else if (rd_en) begin
                // Process read request
                frame_start <= 1'b0;
                
                // Read from current buffer
                case (read_buf)
                    2'b00: pixel_out <= buffer0[rd_y * WIDTH + rd_x];
                    2'b01: pixel_out <= buffer1[rd_y * WIDTH + rd_x];
                    2'b10: pixel_out <= buffer2[rd_y * WIDTH + rd_x];
                endcase
                
                // Update scan coordinates
                if (rd_x == WIDTH-1) begin
                    rd_x <= 8'd0;
                    line_start <= 1'b1;
                    if (rd_y == HEIGHT-1)
                        rd_y <= 8'd0;
                    else
                        rd_y <= rd_y + 8'd1;
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