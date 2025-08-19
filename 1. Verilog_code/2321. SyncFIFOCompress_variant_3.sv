//SystemVerilog
module SyncFIFOCompress #(
    parameter DW = 8,   // Data width
    parameter AW = 12   // Address width
)(
    input  wire           clk,    // Clock input
    input  wire           rst_n,  // Active low reset
    input  wire           wr_en,  // Write enable
    input  wire           rd_en,  // Read enable
    input  wire [DW-1:0]  din,    // Data input
    output reg  [DW-1:0]  dout,   // Data output
    output wire           full,   // FIFO full flag
    output wire           empty   // FIFO empty flag
);

    // Memory declaration
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Pointer registers
    reg [AW:0] wr_ptr = 0;
    reg [AW:0] rd_ptr = 0;
    
    // Fan-out buffering for wr_ptr
    reg [AW:0] wr_ptr_mem  = 0;  // For memory addressing
    reg [AW:0] wr_ptr_full = 0;  // For full flag computation
    
    // Conditional sum-based subtraction for full flag calculation
    wire [AW:0] diff;
    wire [AW:0] rd_ptr_inv;
    wire carry_in = 1'b1; // For two's complement
    wire [AW:0] carry;
    
    // Generate ones' complement of rd_ptr
    assign rd_ptr_inv = ~rd_ptr;
    
    // Generate carry chain for conditional sum subtraction
    assign carry[0] = carry_in;
    genvar i;
    generate
        for (i = 0; i < AW; i = i + 1) begin : gen_carry
            assign carry[i+1] = (wr_ptr_full[i] & rd_ptr_inv[i]) | 
                               ((wr_ptr_full[i] | rd_ptr_inv[i]) & carry[i]);
        end
    endgenerate
    
    // Calculate difference using XOR for sum
    generate
        for (i = 0; i <= AW; i = i + 1) begin : gen_diff
            assign diff[i] = wr_ptr_full[i] ^ rd_ptr_inv[i] ^ carry[i];
        end
    endgenerate
    
    // FIFO flags
    assign full = (diff == (1<<AW));
    assign empty = (wr_ptr == rd_ptr);
    
    // Main control logic
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            wr_ptr_mem <= 0;
            wr_ptr_full <= 0;
        end else begin
            // Write pointer update
            if (wr_en && !full) begin
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            // Read pointer update
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
            
            // Buffer high fan-out wr_ptr signal
            wr_ptr_mem <= wr_ptr;
            wr_ptr_full <= wr_ptr;
        end
    end
    
    // Memory write operation
    always @(posedge clk) begin
        if (rst_n && wr_en && !full) begin
            mem[wr_ptr[AW-1:0]] <= din;
        end
    end
    
    // Memory read operation
    always @(posedge clk) begin
        dout <= mem[rd_ptr[AW-1:0]];
    end

endmodule