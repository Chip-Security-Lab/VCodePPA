//SystemVerilog
module UART_MultiBuffer #(
    parameter BUFFER_LEVEL = 4
)(
    input wire clk,
    input wire [7:0] rx_data,
    input wire rx_valid,
    output wire [7:0] buffer_occupancy,
    input wire buffer_flush
);

    // Internal combinational signals
    wire [7:0] data_pipe_buf_next [0:BUFFER_LEVEL-1];
    wire [2:0] index_buf_next;
    wire [3:0] valid_pipe_buf_next;

    // Internal sequential registers
    reg [7:0] data_pipe_buf [0:BUFFER_LEVEL-1];
    reg [7:0] data_pipe_reg [0:BUFFER_LEVEL-1];

    reg [2:0] index_buf;
    reg [2:0] index_reg;

    reg [3:0] valid_pipe_buf;
    reg [3:0] valid_pipe_reg;

    integer idx_internal;

    // 8-bit subtractor using two's complement addition
    function [7:0] subtract_8bit;
        input [7:0] minuend;
        input [7:0] subtrahend;
        begin
            subtract_8bit = minuend + (~subtrahend + 8'b1);
        end
    endfunction

    // Combinational logic for next buffer state
    genvar idx;
    generate
        for (idx = 0; idx < BUFFER_LEVEL; idx = idx + 1) begin: DATA_PIPE_BUF_COMB
            assign data_pipe_buf_next[idx] = (idx == 0) ? rx_data : data_pipe_reg[subtract_8bit(idx, 8'd1)];
        end
    endgenerate

    assign index_buf_next = 3'd0;

    assign valid_pipe_buf_next = buffer_flush ? 4'b0 : {valid_pipe_reg[2:0], rx_valid};

    // Sequential logic for buffer registers (Stage 1)
    always @(posedge clk) begin
        index_buf <= index_buf_next;
        valid_pipe_buf <= valid_pipe_buf_next;
        for (idx_internal = 0; idx_internal < BUFFER_LEVEL; idx_internal = idx_internal + 1) begin
            data_pipe_buf[idx_internal] <= data_pipe_buf_next[idx_internal];
        end
    end

    // Sequential logic for output registers (Stage 2)
    always @(posedge clk) begin
        index_reg <= index_buf;
        valid_pipe_reg <= valid_pipe_buf;
        for (idx_internal = 0; idx_internal < BUFFER_LEVEL; idx_internal = idx_internal + 1) begin
            data_pipe_reg[idx_internal] <= data_pipe_buf[idx_internal];
        end
    end

    assign buffer_occupancy = {4'b0, valid_pipe_reg};

endmodule