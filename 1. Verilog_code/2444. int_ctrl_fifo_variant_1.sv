//SystemVerilog
module int_ctrl_fifo #(parameter DEPTH=4, parameter DW=8) (
    input wire clk, 
    input wire wr_en, 
    input wire rd_en,
    input wire [DW-1:0] int_data,
    output wire full, 
    output wire empty,
    output reg [DW-1:0] int_out
);
    reg [DW-1:0] fifo [0:DEPTH-1];
    reg [1:0] wr_ptr, rd_ptr;
    reg wr_en_reg, rd_en_reg;
    reg [DW-1:0] int_data_reg;
    reg [1:0] inverted_rd_ptr_reg;
    reg [1:0] wr_ptr_plus_one;
    wire [1:0] inverted_rd_ptr;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk) begin
        wr_en_reg <= wr_en;
        rd_en_reg <= rd_en;
        int_data_reg <= int_data;
        inverted_rd_ptr_reg <= ~rd_ptr;
    end
    
    // Calculate wr_ptr_plus_one in the next cycle after registering inverted_rd_ptr
    always @(posedge clk) begin
        wr_ptr_plus_one <= wr_ptr + 2'b01 + inverted_rd_ptr_reg + 2'b01;
    end
    
    // Use registered control signals
    always @(posedge clk) begin
        if(wr_en_reg && !full) begin
            fifo[wr_ptr] <= int_data_reg;
            wr_ptr <= wr_ptr + 2'b01;
        end
        if(rd_en_reg && !empty) begin
            int_out <= fifo[rd_ptr];
            rd_ptr <= rd_ptr + 2'b01;
        end
    end
    
    // Direct computation for empty condition
    assign empty = wr_ptr == rd_ptr;
    
    // Use registered wr_ptr_plus_one for full condition
    assign full = wr_ptr_plus_one[1:0] == 2'b00;
    
    // Original inverted_rd_ptr calculation kept for timing analysis purposes
    assign inverted_rd_ptr = ~rd_ptr;
    
endmodule