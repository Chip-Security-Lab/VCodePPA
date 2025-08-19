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
    reg [4:0] bit_count, next_bit_count;
    reg [7:0] data_out, next_data_out;
    reg [3:0] io_out, next_io_out, io_oe, next_io_oe;  // Output enables for IO pins

    // Tri-state outputs
    assign spi_io[0] = io_oe[0] ? io_out[0] : 1'bz;
    assign spi_io[1] = io_oe[1] ? io_out[1] : 1'bz;
    assign spi_io[2] = io_oe[2] ? io_out[2] : 1'bz;
    assign spi_io[3] = io_oe[3] ? io_out[3] : 1'bz;

    // State Register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Bit Counter Register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            bit_count <= 5'd0;
        end else begin
            bit_count <= next_bit_count;
        end
    end

    // Data Out Register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 8'd0;
        end else begin
            data_out <= next_data_out;
        end
    end

    // IO Output Register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            io_out <= 4'b0000;
        end else begin
            io_out <= next_io_out;
        end
    end

    // IO Output Enable Register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            io_oe <= 4'b0000;
        end else begin
            io_oe <= next_io_oe;
        end
    end

    // Busy Signal
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy <= 1'b0;
        end else if (state == IDLE && start) begin
            busy <= 1'b1;
        end else if (state == END) begin
            busy <= 1'b0;
        end
    end

    // Done Signal
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            done <= 1'b0;
        end else if (state == END) begin
            done <= 1'b1;
        end else if (state == IDLE) begin
            done <= 1'b0;
        end
    end

    // SPI CS_n Signal
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_cs_n <= 1'b1;
        end else if (state == IDLE && start) begin
            spi_cs_n <= 1'b0;
        end else if (state == END) begin
            spi_cs_n <= 1'b1;
        end
    end

    // SPI CLK Signal (kept static as in original code)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_clk <= 1'b0;
        end
    end

    // Next State Logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = CMD;
                else
                    next_state = IDLE;
            end
            CMD: begin
                if (bit_count == 0)
                    next_state = ADDR;
                else
                    next_state = CMD;
            end
            ADDR: begin
                if (bit_count == 0) begin
                    if (write_en)
                        next_state = DATA_W;
                    else
                        next_state = DATA_R;
                end else
                    next_state = ADDR;
            end
            DATA_W: begin
                if (bit_count == 0)
                    next_state = END;
                else
                    next_state = DATA_W;
            end
            DATA_R: begin
                if (bit_count == 0)
                    next_state = END;
                else
                    next_state = DATA_R;
            end
            END: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Next Bit Counter Logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_bit_count = 5'd7;
                else
                    next_bit_count = bit_count;
            end
            CMD: begin
                if (bit_count == 0)
                    next_bit_count = ADDR_WIDTH - 1;
                else
                    next_bit_count = bit_count - 1'b1;
            end
            ADDR: begin
                if (bit_count == 0)
                    next_bit_count = 5'd7;
                else
                    next_bit_count = bit_count - 1'b1;
            end
            DATA_W: begin
                if (bit_count == 0)
                    next_bit_count = bit_count;
                else
                    next_bit_count = bit_count - 1'b1;
            end
            DATA_R: begin
                if (bit_count == 0)
                    next_bit_count = bit_count;
                else
                    next_bit_count = bit_count - 1'b1;
            end
            END: begin
                next_bit_count = 5'd0;
            end
            default: next_bit_count = 5'd0;
        endcase
    end

    // Next Data Out Logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_data_out = cmd;
                else
                    next_data_out = data_out;
            end
            CMD: begin
                next_data_out = data_out;
            end
            ADDR: begin
                next_data_out = data_out;
            end
            DATA_W: begin
                next_data_out = data_out;
            end
            DATA_R: begin
                next_data_out = {data_out[6:0], spi_io[1]};
            end
            END: begin
                next_data_out = data_out;
            end
            default: next_data_out = data_out;
        endcase
    end

    // Next IO Output Logic
    always @(*) begin
        next_io_out = io_out;
        case (state)
            CMD: begin
                next_io_out[0] = data_out[bit_count];
            end
            ADDR: begin
                next_io_out[0] = addr[bit_count];
            end
            DATA_W: begin
                next_io_out[0] = write_data[bit_count];
            end
            default: ;
        endcase
    end

    // Next IO Output Enable Logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_io_oe = 4'b0001;
                else
                    next_io_oe = 4'b0000;
            end
            CMD: begin
                next_io_oe = 4'b0001;
            end
            ADDR: begin
                if (write_en)
                    next_io_oe = 4'b0001;
                else
                    next_io_oe = 4'b0000;
            end
            DATA_W: begin
                next_io_oe = 4'b0001;
            end
            DATA_R: begin
                next_io_oe = 4'b0000;
            end
            END: begin
                next_io_oe = 4'b0000;
            end
            default: next_io_oe = 4'b0000;
        endcase
    end

    // Read Data Register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            read_data <= 8'd0;
        end else if (state == DATA_R && bit_count == 0) begin
            read_data <= data_out;
        end
    end

endmodule