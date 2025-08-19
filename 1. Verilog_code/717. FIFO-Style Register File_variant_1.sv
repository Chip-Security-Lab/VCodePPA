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
                  
    // Two's complement subtraction for count calculation
    wire [PTR_WIDTH:0] rd_ptr_comp = ~rd_ptr + 1'b1;
    assign count = wr_ptr + rd_ptr_comp;
    
    // Write (push) operation
    always @(posedge clk) begin
        case ({rst, push, full})
            3'b100: wr_ptr <= 0;
            3'b010: begin
                fifo_mem[wr_ptr[PTR_WIDTH-1:0]] <= push_data;
                wr_ptr <= wr_ptr + 1;
            end
            default: wr_ptr <= wr_ptr;
        endcase
    end
    
    // Read (pop) operation
    always @(posedge clk) begin
        case ({rst, pop, empty})
            3'b100: begin
                rd_ptr <= 0;
                pop_data <= 0;
            end
            3'b010: begin
                pop_data <= fifo_mem[rd_ptr[PTR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
            default: rd_ptr <= rd_ptr;
        endcase
    end
endmodule