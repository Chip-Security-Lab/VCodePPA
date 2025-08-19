//SystemVerilog
module async_fifo_ctrl #(
    parameter DEPTH = 16,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input wire wr_clk, rd_clk, rst_n,
    input wire wr_en, rd_en,
    output reg full, empty,
    output reg [PTR_WIDTH:0] level
);

    // Pointer declarations
    reg [PTR_WIDTH:0] wr_ptr, rd_ptr;
    reg [PTR_WIDTH:0] wr_ptr_sync, rd_ptr_sync;
    reg [PTR_WIDTH:0] level_temp;
    reg borrow;

    // Write pointer control
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // Read pointer synchronization to write clock domain
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_sync <= 0;
        end else begin
            rd_ptr_sync <= rd_ptr;
        end
    end

    // Read pointer control
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // Write pointer synchronization to read clock domain
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_sync <= 0;
        end else begin
            wr_ptr_sync <= wr_ptr;
        end
    end

    // Full flag generation
    always @(*) begin
        full = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr_sync[PTR_WIDTH-1:0]) && 
               (wr_ptr[PTR_WIDTH] != rd_ptr_sync[PTR_WIDTH]);
    end

    // Empty flag generation
    always @(*) begin
        empty = (wr_ptr_sync == rd_ptr);
    end

    // Level calculation using carry-lookahead subtraction
    always @(*) begin
        reg [PTR_WIDTH:0] carry;
        reg [PTR_WIDTH:0] diff;
        reg [PTR_WIDTH:0] a, b;
        
        a = wr_ptr_sync;
        b = rd_ptr;
        
        // Generate carry signals
        carry[0] = 1'b1;
        for (int i = 0; i <= PTR_WIDTH; i++) begin
            carry[i+1] = (a[i] & ~b[i]) | ((a[i] ^ ~b[i]) & carry[i]);
        end
        
        // Calculate difference
        for (int i = 0; i <= PTR_WIDTH; i++) begin
            diff[i] = a[i] ^ ~b[i] ^ carry[i];
        end
        
        level_temp = diff;
        borrow = carry[PTR_WIDTH+1];
    end

    // Level calculation - final result
    always @(*) begin
        level = borrow ? -level_temp : level_temp;
    end

endmodule