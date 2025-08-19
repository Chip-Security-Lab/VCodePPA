//SystemVerilog
//IEEE 1364-2005 Verilog
`timescale 1ns/1ps

module quad_spi_controller #(parameter ADDR_WIDTH = 24) (
    input  wire               clk,
    input  wire               reset_n,
    input  wire               start,
    input  wire               write_en,
    input  wire [7:0]         cmd,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [7:0]         write_data,
    output reg  [7:0]         read_data,
    output reg                busy,
    output reg                done,
    // Quad SPI interface
    output reg                spi_clk,
    output reg                spi_cs_n,
    inout  wire [3:0]         spi_io
);

    localparam IDLE   = 3'd0,
               CMD    = 3'd1,
               ADDR   = 3'd2,
               DATA_W = 3'd3,
               DATA_R = 3'd4,
               END    = 3'd5;

    reg [2:0] state, next_state;
    reg [4:0] bit_count;
    reg [7:0] data_out;
    reg [3:0] io_out;
    reg [3:0] io_oe;

    // Forward retiming input registers: move them after combinational logic
    reg [7:0] pipeline_cmd_bit;
    reg [7:0] pipeline_addr_bit;
    reg [7:0] pipeline_write_data_bit;
    reg [ADDR_WIDTH-1:0] addr_pipe;
    reg write_en_pipe;
    reg [7:0] cmd_pipe;
    reg [7:0] write_data_pipe;

    // Tri-state outputs
    assign spi_io[0] = io_oe[0] ? io_out[0] : 1'bz;
    assign spi_io[1] = io_oe[1] ? io_out[1] : 1'bz;
    assign spi_io[2] = io_oe[2] ? io_out[2] : 1'bz;
    assign spi_io[3] = io_oe[3] ? io_out[3] : 1'bz;

    // Remove input-side registers, retime them after combinational logic

    // Pipeline registers for combinational logic slicing (key path cut)
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pipeline_cmd_bit        <= 8'd0;
            pipeline_addr_bit       <= 8'd0;
            pipeline_write_data_bit <= 8'd0;
            cmd_pipe                <= 8'd0;
            addr_pipe               <= {ADDR_WIDTH{1'b0}};
            write_data_pipe         <= 8'd0;
            write_en_pipe           <= 1'b0;
        end else begin
            // Pipeline for CMD state
            if (state == CMD) begin
                pipeline_cmd_bit <= data_out[bit_count];
            end
            // Pipeline for ADDR state
            if (state == ADDR) begin
                pipeline_addr_bit <= addr_pipe[bit_count];
            end
            // Pipeline for DATA_W state
            if (state == DATA_W) begin
                pipeline_write_data_bit <= write_data_pipe[bit_count];
            end
            // Retimed register updates after combinational logic
            if (state == IDLE && start) begin
                cmd_pipe        <= cmd;
                addr_pipe       <= addr;
                write_data_pipe <= write_data;
                write_en_pipe   <= write_en;
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state      <= IDLE;
            busy       <= 1'b0;
            done       <= 1'b0;
            spi_cs_n   <= 1'b1;
            spi_clk    <= 1'b0;
            bit_count  <= 5'd0;
            io_oe      <= 4'b0000;
            io_out     <= 4'd0;
            data_out   <= 8'd0;
            read_data  <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    done      <= 1'b0;
                    spi_clk   <= 1'b0;
                    if (start) begin
                        busy      <= 1'b1;
                        spi_cs_n  <= 1'b0;
                        data_out  <= cmd;
                        state     <= CMD;
                        bit_count <= 5'd7;
                        io_oe     <= 4'b0001;
                        // Register inputs after combinational logic
                        // cmd_pipe, addr_pipe, write_data_pipe, write_en_pipe updated in pipeline always block
                    end else begin
                        busy      <= 1'b0;
                        spi_cs_n  <= 1'b1;
                        bit_count <= 5'd0;
                        io_oe     <= 4'b0000;
                        state     <= IDLE;
                    end
                end

                CMD: begin
                    // Pipeline reg used for io_out
                    io_out[0] <= pipeline_cmd_bit;
                    if (bit_count == 0) begin
                        state     <= ADDR;
                        bit_count <= ADDR_WIDTH - 1;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end

                ADDR: begin
                    io_out[0] <= pipeline_addr_bit;
                    if (bit_count == 0) begin
                        state     <= write_en_pipe ? DATA_W : DATA_R;
                        bit_count <= 5'd7;
                        io_oe     <= write_en_pipe ? 4'b0001 : 4'b0000;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end

                DATA_W: begin
                    io_out[0] <= pipeline_write_data_bit;
                    if (bit_count == 0) begin
                        state <= END;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end

                DATA_R: begin
                    data_out <= {data_out[6:0], spi_io[1]};
                    if (bit_count == 0) begin
                        state     <= END;
                        read_data <= data_out;
                    end else begin
                        bit_count <= bit_count - 1;
                    end
                end

                END: begin
                    spi_cs_n <= 1'b1;
                    busy     <= 1'b0;
                    done     <= 1'b1;
                    state    <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule