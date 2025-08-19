//SystemVerilog
module sync_fifo #(parameter DW=8, AW=4) (
    input wr_clk, rd_clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full, empty
);
    // Memory array
    reg [DW-1:0] mem[(1<<AW)-1:0];
    
    // Binary counters for read and write pointers
    reg [AW:0] wr_ptr_bin=0, rd_ptr_bin=0;
    
    // Gray-coded pointers for clock domain crossing
    reg [AW:0] wr_ptr_gray=0, rd_ptr_gray=0;
    
    // Synchronized pointers (2-FF synchronizers)
    reg [AW:0] rd_ptr_gray_sync1=0, rd_ptr_gray_sync2=0;
    reg [AW:0] wr_ptr_gray_sync1=0, wr_ptr_gray_sync2=0;
    
    // Convert binary to gray code
    function [AW:0] bin_to_gray;
        input [AW:0] bin;
        begin
            bin_to_gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // Convert gray to binary
    function [AW:0] gray_to_bin;
        input [AW:0] gray;
        reg [AW:0] bin;
        integer i;
        begin
            bin = gray;
            for (i = 1; i <= AW; i = i + 1)
                bin = bin ^ (gray >> i);
            gray_to_bin = bin;
        end
    endfunction
    
    // Write pointer reset logic
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end
    end
    
    // Memory write logic
    always @(posedge wr_clk) begin
        if (rst_n && wr_en && !full) begin
            mem[wr_ptr_bin[AW-1:0]] <= din;
        end
    end
    
    // Write pointer update logic
    always @(posedge wr_clk) begin
        if (rst_n && wr_en && !full) begin
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
        end
    end
    
    // Read pointer reset logic
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
        end
    end
    
    // Read pointer update logic
    always @(posedge rd_clk) begin
        if (rst_n && rd_en && !empty) begin
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
        end
    end
    
    // Write pointer synchronization reset logic
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end
    end
    
    // Write pointer synchronization update logic
    always @(posedge rd_clk) begin
        if (rst_n) begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end
    
    // Read pointer synchronization reset logic
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end
    end
    
    // Read pointer synchronization update logic
    always @(posedge wr_clk) begin
        if (rst_n) begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end
    
    // Data output
    assign dout = mem[rd_ptr_bin[AW-1:0]];
    
    // Calculate full flag using parallel prefix subtractor
    wire [AW:0] rd_ptr_bin_sync;
    parallel_prefix_converter #(.WIDTH(AW+1)) gray_to_bin_rd_converter (
        .gray_in(rd_ptr_gray_sync2),
        .bin_out(rd_ptr_bin_sync)
    );
    
    // Generate and propagate signals for full detection
    wire [AW-1:0] wr_rd_diff;
    wire borrow_out;
    parallel_prefix_subtractor #(.WIDTH(AW)) full_subtractor (
        .a(wr_ptr_bin[AW-1:0]),
        .b(rd_ptr_bin_sync[AW-1:0]),
        .diff(wr_rd_diff),
        .borrow_out(borrow_out)
    );
    
    assign full = (wr_rd_diff == 0) && (wr_ptr_bin[AW] != rd_ptr_bin_sync[AW]);
    
    // Calculate empty flag using parallel prefix subtractor
    wire [AW:0] wr_ptr_bin_sync;
    parallel_prefix_converter #(.WIDTH(AW+1)) gray_to_bin_wr_converter (
        .gray_in(wr_ptr_gray_sync2),
        .bin_out(wr_ptr_bin_sync)
    );
    
    wire [AW-1:0] rd_wr_diff;
    wire empty_borrow;
    parallel_prefix_subtractor #(.WIDTH(AW)) empty_subtractor (
        .a(rd_ptr_bin[AW-1:0]),
        .b(wr_ptr_bin_sync[AW-1:0]),
        .diff(rd_wr_diff),
        .borrow_out(empty_borrow)
    );
    
    assign empty = (rd_wr_diff == 0) && (rd_ptr_bin[AW] == wr_ptr_bin_sync[AW]);
    
endmodule

// Parallel Prefix Subtractor Module
module parallel_prefix_subtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    // Generate and propagate signals
    wire [WIDTH-1:0] g; // Generate
    wire [WIDTH-1:0] p; // Propagate
    wire [WIDTH:0] borrow; // Borrow signals
    
    // Initialize borrow_in to 0
    assign borrow[0] = 1'b0;
    
    // Calculate generate and propagate signals
    // Generate: g[i] = ~a[i] & b[i]
    // Propagate: p[i] = ~a[i] | b[i]
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = (~a[i]) & b[i];
            assign p[i] = (~a[i]) | b[i];
        end
    endgenerate
    
    // Parallel prefix network - Kogge-Stone algorithm
    // Level 1
    wire [WIDTH-1:0] g_l1, p_l1;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : prefix_l1
            if (i == 0) begin
                assign g_l1[i] = g[i];
                assign p_l1[i] = p[i];
            end else begin
                assign g_l1[i] = g[i] | (p[i] & g[i-1]);
                assign p_l1[i] = p[i] & p[i-1];
            end
        end
    endgenerate
    
    // Level 2 (for WIDTH > 2)
    wire [WIDTH-1:0] g_l2, p_l2;
    generate
        if (WIDTH > 2) begin
            for (i = 0; i < WIDTH; i = i + 1) begin : prefix_l2
                if (i < 2) begin
                    assign g_l2[i] = g_l1[i];
                    assign p_l2[i] = p_l1[i];
                end else begin
                    assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
                    assign p_l2[i] = p_l1[i] & p_l1[i-2];
                end
            end
        end else begin
            for (i = 0; i < WIDTH; i = i + 1) begin : bypass_l2
                assign g_l2[i] = g_l1[i];
                assign p_l2[i] = p_l1[i];
            end
        end
    endgenerate
    
    // Level 3 (for WIDTH > 4)
    wire [WIDTH-1:0] g_l3, p_l3;
    generate
        if (WIDTH > 4) begin
            for (i = 0; i < WIDTH; i = i + 1) begin : prefix_l3
                if (i < 4) begin
                    assign g_l3[i] = g_l2[i];
                    assign p_l3[i] = p_l2[i];
                end else begin
                    assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
                    assign p_l3[i] = p_l2[i] & p_l2[i-4];
                end
            end
        end else begin
            for (i = 0; i < WIDTH; i = i + 1) begin : bypass_l3
                assign g_l3[i] = g_l2[i];
                assign p_l3[i] = p_l2[i];
            end
        end
    endgenerate
    
    // Final borrow calculation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_calc
            if (i == 0) begin
                assign borrow[i+1] = g[i];
            end else begin
                assign borrow[i+1] = g_l3[i-1];
            end
        end
    endgenerate
    
    // Calculate difference
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : diff_calc
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
        end
    endgenerate
    
    // Output borrow
    assign borrow_out = borrow[WIDTH];
    
endmodule

// Parallel Prefix Gray to Binary Converter
module parallel_prefix_converter #(parameter WIDTH=8) (
    input [WIDTH-1:0] gray_in,
    output [WIDTH-1:0] bin_out
);
    // Implement parallel prefix gray to binary conversion
    wire [WIDTH-1:0][WIDTH-1:0] prefix_xor;
    
    genvar i, j;
    generate
        // Set up first row - direct from input
        for (i = 0; i < WIDTH; i = i + 1) begin : init_stage
            assign prefix_xor[0][i] = gray_in[i];
        end
        
        // Perform parallel prefix XOR operations
        for (i = 1; i < WIDTH; i = i + 1) begin : prefix_stage
            for (j = 0; j < WIDTH; j = j + 1) begin : prefix_bit
                if (j >= i) begin
                    assign prefix_xor[i][j] = prefix_xor[i-1][j] ^ prefix_xor[i-1][j-1];
                end else begin
                    assign prefix_xor[i][j] = prefix_xor[i-1][j];
                end
            end
        end
        
        // Assign output from final stage
        for (i = 0; i < WIDTH; i = i + 1) begin : output_stage
            assign bin_out[i] = prefix_xor[i][i];
        end
    endgenerate
    
endmodule