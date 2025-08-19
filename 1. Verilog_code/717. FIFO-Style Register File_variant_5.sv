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
    
    // Pointers with pipeline stages
    reg [PTR_WIDTH:0] wr_ptr;
    reg [PTR_WIDTH:0] rd_ptr;
    reg [PTR_WIDTH:0] wr_ptr_next;
    reg [PTR_WIDTH:0] rd_ptr_next;
    
    // Pipeline registers for status signals
    reg [PTR_WIDTH:0] count_reg;
    reg [PTR_WIDTH:0] count_next;
    reg empty_reg;
    reg full_reg;
    
    // Pipeline registers for data path
    reg [DATA_W-1:0] pop_data_next;
    reg [PTR_WIDTH-1:0] rd_addr_reg;
    
    // Status calculation pipeline
    always @(posedge clk) begin
        if (rst) begin
            count_reg <= 0;
            count_next <= 0;
            empty_reg <= 1'b1;
            full_reg <= 1'b0;
        end else begin
            count_next <= wr_ptr - rd_ptr;
            count_reg <= count_next;
            empty_reg <= (wr_ptr == rd_ptr);
            full_reg <= (wr_ptr[PTR_WIDTH-1:0] == rd_ptr[PTR_WIDTH-1:0]) && 
                       (wr_ptr[PTR_WIDTH] != rd_ptr[PTR_WIDTH]);
        end
    end
    
    assign count = count_reg;
    assign empty = empty_reg;
    assign full = full_reg;
    
    // Write operation pipeline
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            wr_ptr_next <= 0;
        end else begin
            wr_ptr <= wr_ptr_next;
            if (push && !full_reg) begin
                fifo_mem[wr_ptr[PTR_WIDTH-1:0]] <= push_data;
                wr_ptr_next <= wr_ptr + 1;
            end
        end
    end
    
    // Read operation pipeline
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
            rd_ptr_next <= 0;
            rd_addr_reg <= 0;
            pop_data <= 0;
            pop_data_next <= 0;
        end else begin
            rd_ptr <= rd_ptr_next;
            rd_addr_reg <= rd_ptr[PTR_WIDTH-1:0];
            pop_data <= pop_data_next;
            if (pop && !empty_reg) begin
                pop_data_next <= fifo_mem[rd_addr_reg];
                rd_ptr_next <= rd_ptr + 1;
            end
        end
    end

endmodule