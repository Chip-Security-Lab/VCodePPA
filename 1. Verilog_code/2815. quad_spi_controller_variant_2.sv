//SystemVerilog
module quad_spi_controller #(parameter ADDR_WIDTH = 24) (
    input clk, reset_n,
    input start, write_en,
    input [7:0] cmd,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] write_data,
    output [7:0] read_data,
    output busy, done,
    
    // Quad SPI interface
    output spi_clk, spi_cs_n,
    inout [3:0] spi_io
);

    localparam IDLE = 3'd0, CMD = 3'd1, ADDR = 3'd2;
    localparam DATA_W = 3'd3, DATA_R = 3'd4, END = 3'd5;

    reg [2:0] state, next_state;
    reg [4:0] bit_count, bit_count_r;
    reg [7:0] data_out, data_out_r;
    reg [3:0] io_out, io_out_r;
    reg [3:0] io_oe, io_oe_r;
    reg [ADDR_WIDTH-1:0] addr_r;
    reg [7:0] write_data_r;
    reg [7:0] read_data_r;
    reg busy_r, done_r;
    reg spi_cs_n_r, spi_clk_r;

    // Tri-state outputs
    assign spi_io[0] = io_oe_r[0] ? io_out_r[0] : 1'bz;
    assign spi_io[1] = io_oe_r[1] ? io_out_r[1] : 1'bz;
    assign spi_io[2] = io_oe_r[2] ? io_out_r[2] : 1'bz;
    assign spi_io[3] = io_oe_r[3] ? io_out_r[3] : 1'bz;

    assign read_data = read_data_r;
    assign busy = busy_r;
    assign done = done_r;
    assign spi_cs_n = spi_cs_n_r;
    assign spi_clk = spi_clk_r;

    // Next-state combinational logic for moved registers
    always @(*) begin
        // Default assignments
        next_state = state;
        bit_count_r = bit_count;
        data_out_r = data_out;
        io_out_r = io_out;
        io_oe_r = io_oe;
        addr_r = addr;
        write_data_r = write_data;
        read_data_r = read_data;
        busy_r = busy;
        done_r = done;
        spi_cs_n_r = spi_cs_n;
        spi_clk_r = spi_clk;

        case(state)
            IDLE: begin
                if (start) begin
                    next_state = CMD;
                    bit_count_r = 5'd7;
                    data_out_r = cmd;
                    io_oe_r = 4'b0001;
                    busy_r = 1'b1;
                    spi_cs_n_r = 1'b0;
                end
                done_r = 1'b0;
            end
            CMD: begin
                io_out_r[0] = data_out[bit_count];
                if (bit_count == 0) begin
                    next_state = ADDR;
                    bit_count_r = ADDR_WIDTH - 1;
                end else begin
                    bit_count_r = bit_count - 1;
                end
            end
            ADDR: begin
                io_out_r[0] = addr[bit_count];
                if (bit_count == 0) begin
                    if (write_en) begin
                        next_state = DATA_W;
                        bit_count_r = 5'd7;
                        io_oe_r = 4'b0001;
                    end else begin
                        next_state = DATA_R;
                        bit_count_r = 5'd7;
                        io_oe_r = 4'b0000;
                    end
                end else begin
                    bit_count_r = bit_count - 1;
                end
            end
            DATA_W: begin
                io_out_r[0] = write_data[bit_count];
                if (bit_count == 0) begin
                    next_state = END;
                end else begin
                    bit_count_r = bit_count - 1;
                end
            end
            DATA_R: begin
                if (bit_count == 0) begin
                    next_state = END;
                    read_data_r = {data_out[6:0], spi_io[1]};
                end else begin
                    bit_count_r = bit_count - 1;
                    read_data_r = read_data;
                end
                data_out_r = {data_out[6:0], spi_io[1]};
            end
            END: begin
                spi_cs_n_r = 1'b1;
                busy_r = 1'b0;
                done_r = 1'b1;
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Sequential logic with retimed registers (moved closer to inputs)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            bit_count <= 5'd0;
            data_out <= 8'd0;
            io_out <= 4'b0000;
            io_oe <= 4'b0000;
            addr_r <= {ADDR_WIDTH{1'b0}};
            write_data_r <= 8'd0;
            read_data_r <= 8'd0;
            busy_r <= 1'b0;
            done_r <= 1'b0;
            spi_cs_n_r <= 1'b1;
            spi_clk_r <= 1'b0;
        end else begin
            state <= next_state;
            bit_count <= bit_count_r;
            data_out <= data_out_r;
            io_out <= io_out_r;
            io_oe <= io_oe_r;
            addr_r <= addr;
            write_data_r <= write_data;
            read_data_r <= read_data_r;
            busy_r <= busy_r;
            done_r <= done_r;
            spi_cs_n_r <= spi_cs_n_r;
            spi_clk_r <= spi_clk_r;
        end
    end

endmodule