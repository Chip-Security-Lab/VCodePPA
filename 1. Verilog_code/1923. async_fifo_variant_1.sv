//SystemVerilog
module async_fifo #(parameter DW=16, DEPTH=8) (
    input wr_clk, rd_clk, rst,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output full, empty
);
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [2:0] wr_ptr, rd_ptr;
    reg [2:0] wr_ptr_gray, rd_ptr_gray;
    reg [2:0] rd_ptr_sync, wr_ptr_sync;

    // Brent-Kung 3-bit adder
    function [2:0] brent_kung_adder_3b;
        input [2:0] a, b;
        input cin;
        reg [2:0] p, g;
        reg [2:0] x, y;
        reg [2:0] c;
        begin
            // Pre-processing
            p = a ^ b;
            g = a & b;

            // Stage 1
            x[0] = g[0];
            x[1] = g[1] | (p[1] & g[0]);
            x[2] = g[2] | (p[2] & g[1]);

            // Stage 2 (prefix tree)
            y[0] = x[0];
            y[1] = x[1];
            y[2] = x[2] | (p[2] & x[0]);

            // Carry calculation
            c[0] = cin;
            c[1] = y[0] | (p[0] & cin);
            c[2] = y[1] | (p[1] & c[1]);

            // Sum calculation
            brent_kung_adder_3b = p ^ c;
        end
    endfunction

    // Write domain
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 3'd0;
            wr_ptr_gray <= 3'd0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            // Brent-Kung based increment
            wr_ptr <= brent_kung_adder_3b(wr_ptr, 3'd1, 1'b0);
            wr_ptr_gray <= wr_ptr ^ (wr_ptr >> 1);
        end
    end

    // Read domain
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 3'd0;
            rd_ptr_gray <= 3'd0;
            dout <= {DW{1'b0}};
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr];
            // Brent-Kung based increment
            rd_ptr <= brent_kung_adder_3b(rd_ptr, 3'd1, 1'b0);
            rd_ptr_gray <= rd_ptr ^ (rd_ptr >> 1);
        end
    end

    // Synchronize gray code pointers across clock domains
    always @(posedge wr_clk or posedge rst) begin
        if (rst)
            rd_ptr_sync <= 3'd0;
        else
            rd_ptr_sync <= rd_ptr_gray;
    end

    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            wr_ptr_sync <= 3'd0;
        else
            wr_ptr_sync <= wr_ptr_gray;
    end

    // Full and empty flag logic
    wire [2:0] wr_ptr_gray_next, rd_ptr_gray_next;
    assign wr_ptr_gray_next = wr_ptr ^ (wr_ptr >> 1);
    assign rd_ptr_gray_next = rd_ptr ^ (rd_ptr >> 1);

    wire fifo_full, fifo_empty;
    // full: wr_ptr_gray == {~rd_ptr_sync[2], rd_ptr_sync[1:0]}
    assign fifo_full = (wr_ptr_gray == {~rd_ptr_sync[2], rd_ptr_sync[1:0]});
    // empty: rd_ptr_gray == wr_ptr_sync
    assign fifo_empty = (rd_ptr_gray == wr_ptr_sync);

    assign full = fifo_full;
    assign empty = fifo_empty;

endmodule