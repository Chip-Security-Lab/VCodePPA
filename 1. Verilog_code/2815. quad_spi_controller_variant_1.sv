//SystemVerilog
module quad_spi_controller #(parameter ADDR_WIDTH = 24) (
    input clk, reset_n,
    input start, write_en,
    input [7:0] cmd,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] write_data,
    output reg [7:0] read_data,
    output reg busy, done,
    
    // Quad SPI interface
    output reg spi_clk, spi_cs_n,
    inout [3:0] spi_io
);
    localparam IDLE = 3'd0, CMD = 3'd1, ADDR = 3'd2;
    localparam DATA_W = 3'd3, DATA_R = 3'd4, END = 3'd5;
    
    reg [2:0] state, next_state;
    reg [4:0] bit_count;
    reg [7:0] data_out;
    reg [3:0] io_out, io_oe;  // Output enables for IO pins

    // 用于补码加法实现减法
    wire [4:0] bit_count_minus1;
    assign bit_count_minus1 = bit_count + (~5'd1 + 1'b1); // bit_count - 1, 补码加法

    // Tri-state outputs
    assign spi_io[0] = (io_oe[0] == 1'b1) ? io_out[0] : 1'bz;
    assign spi_io[1] = (io_oe[1] == 1'b1) ? io_out[1] : 1'bz;
    assign spi_io[2] = (io_oe[2] == 1'b1) ? io_out[2] : 1'bz;
    assign spi_io[3] = (io_oe[3] == 1'b1) ? io_out[3] : 1'bz;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            busy <= 1'b0;
            done <= 1'b0;
            spi_cs_n <= 1'b1;
            spi_clk <= 1'b0;
            bit_count <= 5'd0;
            io_oe <= 4'b0000;
            data_out <= 8'd0;
            io_out <= 4'd0;
            read_data <= 8'd0;
        end else begin
            case(state)
                IDLE: begin
                    if (start) begin
                        busy <= 1'b1;
                        spi_cs_n <= 1'b0;
                        data_out <= cmd;
                        state <= CMD;
                        bit_count <= 5'd7;
                        io_oe <= 4'b0001;
                    end else begin
                        done <= 1'b0;
                    end
                end
                CMD: begin
                    io_out[0] <= data_out[bit_count];
                    if (bit_count == 5'd0) begin
                        state <= ADDR;
                        bit_count <= ADDR_WIDTH[4:0] - 1'b1;
                    end else begin
                        bit_count <= bit_count_minus1;
                    end
                end
                ADDR: begin
                    io_out[0] <= addr[bit_count];
                    if (bit_count == 5'd0) begin
                        if (write_en) begin
                            state <= DATA_W;
                            bit_count <= 5'd7;
                            io_oe <= 4'b0001;
                        end else begin
                            state <= DATA_R;
                            bit_count <= 5'd7;
                            io_oe <= 4'b0000;
                        end
                    end else begin
                        bit_count <= bit_count_minus1;
                    end
                end
                DATA_W: begin
                    io_out[0] <= write_data[bit_count];
                    if (bit_count == 5'd0) begin
                        state <= END;
                    end else begin
                        bit_count <= bit_count_minus1;
                    end
                end
                DATA_R: begin
                    data_out <= {data_out[6:0], spi_io[1]};
                    if (bit_count == 5'd0) begin
                        state <= END;
                        read_data <= data_out;
                    end else begin
                        bit_count <= bit_count_minus1;
                    end
                end
                END: begin
                    spi_cs_n <= 1'b1;
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule