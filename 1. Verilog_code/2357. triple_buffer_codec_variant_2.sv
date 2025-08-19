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
    
    // Registered inputs for Karatsuba multiplier
    reg [7:0] wr_x_reg, wr_y_reg;
    reg wr_en_reg;
    reg [DATA_WIDTH-1:0] pixel_in_reg;
    
    // Karatsuba multiplier for address calculation (8-bit)
    wire [15:0] karatsuba_result;
    reg [ADDR_WIDTH-1:0] write_addr;
    
    // Registered inputs for read address calculation
    reg [7:0] rd_x_next, rd_y_next;
    reg buffer_swap_reg;
    reg rd_en_reg;
    
    // Read address calculation
    wire [15:0] read_karatsuba_result;
    wire [ADDR_WIDTH-1:0] read_addr_wire;
    
    // Register input signals
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_x_reg <= 8'd0;
            wr_y_reg <= 8'd0;
            wr_en_reg <= 1'b0;
            pixel_in_reg <= {DATA_WIDTH{1'b0}};
            buffer_swap_reg <= 1'b0;
            rd_en_reg <= 1'b0;
        end else begin
            wr_x_reg <= wr_x;
            wr_y_reg <= wr_y;
            wr_en_reg <= wr_en;
            pixel_in_reg <= pixel_in;
            buffer_swap_reg <= buffer_swap;
            rd_en_reg <= rd_en;
        end
    end
    
    // Karatsuba multiplier for write address
    karatsuba_multiplier_8bit addr_mult (
        .a(wr_y_reg),
        .b(WIDTH[7:0]),
        .product(karatsuba_result)
    );
    
    // Write address calculation using Karatsuba multiplier result
    always @(posedge clk) begin
        write_addr <= karatsuba_result[ADDR_WIDTH-1:0] + wr_x_reg;
    end
    
    // Karatsuba multiplier for read address
    karatsuba_multiplier_8bit read_addr_mult (
        .a(rd_y),
        .b(WIDTH[7:0]),
        .product(read_karatsuba_result)
    );
    
    assign read_addr_wire = read_karatsuba_result[ADDR_WIDTH-1:0] + rd_x;
    
    // Write operation (moved register)
    always @(posedge clk) begin
        if (wr_en_reg) begin
            case (write_buf)
                2'b00: buffer0[write_addr] <= pixel_in_reg;
                2'b01: buffer1[write_addr] <= pixel_in_reg;
                2'b10: buffer2[write_addr] <= pixel_in_reg;
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
            rd_x_next <= 8'd0;
            rd_y_next <= 8'd0;
            frame_start <= 1'b0;
            line_start <= 1'b0;
            pixel_out <= {DATA_WIDTH{1'b0}};
        end else begin
            if (buffer_swap_reg) begin
                // Rotate buffers
                read_buf <= display_buf;
                display_buf <= write_buf;
                write_buf <= read_buf;
                
                // Reset scan coordinates
                rd_x <= 8'd0;
                rd_y <= 8'd0;
                rd_x_next <= 8'd0;
                rd_y_next <= 8'd0;
                frame_start <= 1'b1;
                line_start <= 1'b1;
            end else if (rd_en_reg) begin
                // Process read request
                frame_start <= 1'b0;
                rd_x <= rd_x_next;
                rd_y <= rd_y_next;
                
                // Read from current buffer using calculated address
                case (read_buf)
                    2'b00: pixel_out <= buffer0[read_addr_wire];
                    2'b01: pixel_out <= buffer1[read_addr_wire];
                    2'b10: pixel_out <= buffer2[read_addr_wire];
                endcase
                
                // Pre-compute next scan coordinates
                if (rd_x_next == WIDTH-1) begin
                    rd_x_next <= 8'd0;
                    line_start <= 1'b1;
                    if (rd_y_next == HEIGHT-1)
                        rd_y_next <= 8'd0;
                    else
                        rd_y_next <= rd_y_next + 8'd1;
                end else begin
                    rd_x_next <= rd_x_next + 8'd1;
                    line_start <= 1'b0;
                end
            end else begin
                frame_start <= 1'b0;
                line_start <= 1'b0;
            end
        end
    end
endmodule

module karatsuba_multiplier_8bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    // Split inputs into high and low nibbles
    wire [3:0] a_high, a_low, b_high, b_low;
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // Calculate partial products
    wire [7:0] a_sum, b_sum;
    reg [7:0] high_product;
    reg [7:0] low_product;
    reg [7:0] mid_term;
    
    // Sum of the high and low parts
    assign a_sum = {4'b0000, a_high} + {4'b0000, a_low};
    assign b_sum = {4'b0000, b_high} + {4'b0000, b_low};
    
    // Calculate partial products
    always @(*) begin
        high_product = a_high * b_high;
        low_product = a_low * b_low;
        mid_term = a_sum * b_sum - high_product - low_product;
    end
    
    // Combine partial products to get the final result
    assign product = {high_product, 8'b0} + {mid_term, 4'b0} + {8'b0, low_product};
endmodule