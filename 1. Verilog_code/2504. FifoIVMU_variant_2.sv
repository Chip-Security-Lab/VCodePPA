//SystemVerilog
module FifoIVMU #(parameter DEPTH = 4, parameter ADDR_W = 32) (
    input clk, rst,
    input [7:0] new_irq,
    input ack,
    output [ADDR_W-1:0] curr_vector,
    output has_pending
);
    reg [ADDR_W-1:0] vector_fifo [0:DEPTH-1];
    reg [ADDR_W-1:0] vector_table [0:7];
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    wire empty, full;
    integer i;

    reg [$clog2(DEPTH):0] next_wr_ptr, next_rd_ptr;
    reg [ADDR_W-1:0] data_to_write;
    reg write_strobe;

    initial for (i = 0; i < 8; i = i + 1)
        vector_table[i] = 32'h3000_0000 + (i << 3);

    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]) &&
                 (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]);
    assign has_pending = ~empty;
    assign curr_vector = empty ? 0 : vector_fifo[rd_ptr[$clog2(DEPTH)-1:0]];

    always @* begin
        next_wr_ptr = wr_ptr;
        next_rd_ptr = rd_ptr;
        data_to_write = 0;
        write_strobe = 0;

        // Determine write action based on priority (0 is highest) and full status
        // Flattened conditions using &&
        if (!full) begin
            if (new_irq[0]) begin
                write_strobe = 1;
                data_to_write = vector_table[0];
            end else if (!new_irq[0] && new_irq[1]) begin
                write_strobe = 1;
                data_to_write = vector_table[1];
            end else if (!new_irq[0] && !new_irq[1] && new_irq[2]) begin
                write_strobe = 1;
                data_to_write = vector_table[2];
            end else if (!new_irq[0] && !new_irq[1] && !new_irq[2] && new_irq[3]) begin
                write_strobe = 1;
                data_to_write = vector_table[3];
            end else if (!new_irq[0] && !new_irq[1] && !new_irq[2] && !new_irq[3] && new_irq[4]) begin
                write_strobe = 1;
                data_to_write = vector_table[4];
            end else if (!new_irq[0] && !new_irq[1] && !new_irq[2] && !new_irq[3] && !new_irq[4] && new_irq[5]) begin
                write_strobe = 1;
                data_to_write = vector_table[5];
            end else if (!new_irq[0] && !new_irq[1] && !new_irq[2] && !new_irq[3] && !new_irq[4] && !new_irq[5] && new_irq[6]) begin
                write_strobe = 1;
                data_to_write = vector_table[6];
            end else if (!new_irq[0] && !new_irq[1] && !new_irq[2] && !new_irq[3] && !new_irq[4] && !new_irq[5] && !new_irq[6] && new_irq[7]) begin
                write_strobe = 1;
                data_to_write = vector_table[7];
            end
        end

        if (write_strobe) begin
            next_wr_ptr = wr_ptr + 1;
        end

        if (ack && !empty) begin
            next_rd_ptr = rd_ptr + 1;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            wr_ptr <= next_wr_ptr;
            rd_ptr <= next_rd_ptr;

            if (write_strobe) begin
                vector_fifo[wr_ptr[$clog2(DEPTH)-1:0]] <= data_to_write;
            end
        end
    end
endmodule