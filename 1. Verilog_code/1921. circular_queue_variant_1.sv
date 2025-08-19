//SystemVerilog
`timescale 1ns/1ps

module circular_queue #(parameter DW=8, DEPTH=16) (
    input                   clk,
    input                   rst_n,
    input                   en,
    input  [DW-1:0]         data_in,
    output [DW-1:0]         data_out,
    output                  full,
    output                  empty
);

    reg [DW-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] r_ptr, w_ptr;
    reg [4:0]               count;

    // Pipeline registers moved to before memory access and flag generation
    reg [$clog2(DEPTH)-1:0] w_ptr_pipe1, r_ptr_pipe1;
    reg [4:0]               count_pipe1;
    reg [DW-1:0]            data_in_pipe1;
    reg                     write_en_pipe1, read_en_pipe1;

    reg [$clog2(DEPTH)-1:0] w_ptr_pipe2, r_ptr_pipe2;
    reg [4:0]               count_pipe2;
    reg [DW-1:0]            data_in_pipe2;
    reg                     write_en_pipe2, read_en_pipe2;

    // Output registers moved before the output assignments (retiming)
    reg [DW-1:0]            data_out_reg;
    reg                     full_reg, empty_reg;

    // Stage 1: Prepare next pointers and enable signals (pipeline registers BEFORE memory/flag access)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr_pipe1    <= 0;
            r_ptr_pipe1    <= 0;
            count_pipe1    <= 0;
            data_in_pipe1  <= 0;
            write_en_pipe1 <= 1'b0;
            read_en_pipe1  <= 1'b0;
        end else if (en) begin
            write_en_pipe1 <= (count != DEPTH);
            read_en_pipe1  <= (count != 0);
            w_ptr_pipe1    <= (w_ptr + 1) % DEPTH;
            r_ptr_pipe1    <= (r_ptr + 1) % DEPTH;
            count_pipe1    <= count;
            data_in_pipe1  <= data_in;
        end else begin
            write_en_pipe1 <= 1'b0;
            read_en_pipe1  <= 1'b0;
        end
    end

    // Stage 2: Pipeline registers continue (BEFORE memory/flag access)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_ptr_pipe2    <= 0;
            r_ptr_pipe2    <= 0;
            count_pipe2    <= 0;
            data_in_pipe2  <= 0;
            write_en_pipe2 <= 1'b0;
            read_en_pipe2  <= 1'b0;
        end else begin
            w_ptr_pipe2    <= w_ptr_pipe1;
            r_ptr_pipe2    <= r_ptr_pipe1;
            count_pipe2    <= count_pipe1;
            data_in_pipe2  <= data_in_pipe1;
            write_en_pipe2 <= write_en_pipe1;
            read_en_pipe2  <= read_en_pipe1;
        end
    end

    // Stage 3: Actual queue operation, now output registers are updated before output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_ptr      <= 0;
            w_ptr      <= 0;
            count      <= 0;
            data_out_reg <= 0;
            full_reg   <= 1'b0;
            empty_reg  <= 1'b1;
        end else begin
            // Write operation
            if (en && write_en_pipe2) begin
                mem[w_ptr] <= data_in_pipe2;
                w_ptr      <= w_ptr_pipe2;
                count      <= count + 1'b1;
            end

            // Read operation
            if (en && read_en_pipe2) begin
                data_out_reg <= mem[r_ptr];
                r_ptr        <= r_ptr_pipe2;
                count        <= count - 1'b1;
            end

            // Update status flags
            full_reg  <= (count == DEPTH);
            empty_reg <= (count == 0);
        end
    end

    // Output pipeline (registers moved before output assignment for retiming)
    reg [DW-1:0]            data_out_pipe;
    reg                     full_pipe, empty_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_pipe <= 0;
            full_pipe     <= 1'b0;
            empty_pipe    <= 1'b1;
        end else begin
            data_out_pipe <= data_out_reg;
            full_pipe     <= full_reg;
            empty_pipe    <= empty_reg;
        end
    end

    assign data_out = data_out_pipe;
    assign full     = full_pipe;
    assign empty    = empty_pipe;

endmodule