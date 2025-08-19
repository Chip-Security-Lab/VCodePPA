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
    
    // Tri-state outputs
    assign spi_io[0] = io_oe[0] ? io_out[0] : 1'bz;
    assign spi_io[1] = io_oe[1] ? io_out[1] : 1'bz;
    assign spi_io[2] = io_oe[2] ? io_out[2] : 1'bz;
    assign spi_io[3] = io_oe[3] ? io_out[3] : 1'bz;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE; busy <= 0; done <= 0; spi_cs_n <= 1;
            spi_clk <= 0; bit_count <= 0; io_oe <= 4'b0000;
        end else begin
            case(state)
                IDLE: if (start) begin
                    busy <= 1; spi_cs_n <= 0; data_out <= cmd;
                    state <= CMD; bit_count <= 7; io_oe <= 4'b0001;
                end
                CMD: begin // 完善Command状态逻辑
                    if (bit_count == 0) begin
                        state <= ADDR;
                        bit_count <= ADDR_WIDTH-1;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                    io_out[0] <= data_out[bit_count];
                end
                ADDR: begin // 添加ADDR状态逻辑
                    if (bit_count == 0) begin
                        state <= write_en ? DATA_W : DATA_R;
                        bit_count <= 7;
                        io_oe <= write_en ? 4'b0001 : 4'b0000;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                    io_out[0] <= addr[bit_count];
                end
                DATA_W: begin // 添加DATA_W状态逻辑
                    if (bit_count == 0) begin
                        state <= END;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                    io_out[0] <= write_data[bit_count];
                end
                DATA_R: begin // 添加DATA_R状态逻辑
                    if (bit_count == 0) begin
                        state <= END;
                        read_data <= data_out;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                    data_out <= {data_out[6:0], spi_io[1]};
                end
                END: begin
                    spi_cs_n <= 1; busy <= 0; done <= 1; state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule