//SystemVerilog
module fifo_regfile #(
    parameter DATA_W = 16,
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH)
)(
    input  wire                clk,
    input  wire                rst,
    
    // Write interface (push)
    input  wire                push,
    input  wire [DATA_W-1:0]   push_data,
    output wire                full,
    
    // Read interface (pop)
    input  wire                pop,
    output reg  [DATA_W-1:0]   pop_data,
    output wire                empty,
    
    // Status
    output wire [PTR_WIDTH:0]  count
);

    // Register file storage
    reg [DATA_W-1:0] fifo_mem [0:DEPTH-1];
    
    // Pointers
    reg [PTR_WIDTH:0] wr_ptr;
    reg [PTR_WIDTH:0] rd_ptr;
    
    // Status signals
    assign empty = (wr_ptr == rd_ptr);
    assign full = (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) && 
                  (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]);

    // Parallel prefix subtractor for count calculation
    wire [PTR_WIDTH:0] borrow;
    wire [PTR_WIDTH:0] diff;
    
    // Generate borrow signals using parallel prefix method
    wire [PTR_WIDTH:0] g, p; // Generate and Propagate signals
    genvar i;
    generate
        for(i = 0; i < PTR_WIDTH; i = i + 1) begin : gen_g_p
            assign g[i] = rd_ptr[i] & ~wr_ptr[i]; // Generate
            assign p[i] = rd_ptr[i] | ~wr_ptr[i]; // Propagate
        end
    endgenerate

    // Calculate borrow using parallel prefix logic
    assign borrow[0] = 1'b0; // Initial borrow
    generate
        for(i = 1; i <= PTR_WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i] = g[i-1] | (p[i-1] & borrow[i-1]);
        end
    endgenerate

    // Calculate difference
    generate
        for(i = 0; i <= PTR_WIDTH; i = i + 1) begin : gen_diff
            assign diff[i] = wr_ptr[i] ^ rd_ptr[i] ^ borrow[i];
        end
    endgenerate

    assign count = diff;
    
    // Write (push) operation
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end 
        else if (push && !full) begin
            fifo_mem[wr_ptr[PTR_WIDTH-1:0]] <= push_data;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Read (pop) operation
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            pop_data <= 0;
        end 
        else if (pop && !empty) begin
            pop_data <= fifo_mem[rd_ptr[PTR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
        end
    end
endmodule