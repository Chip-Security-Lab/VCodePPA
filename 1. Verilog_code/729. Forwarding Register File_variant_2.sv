//SystemVerilog
module forwarding_regfile #(
    parameter DATA_WIDTH = 32,
    parameter REG_COUNT = 32,
    parameter ADDR_WIDTH = $clog2(REG_COUNT)
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Write port
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    
    // Read ports
    input  wire [ADDR_WIDTH-1:0]  rd_addr1,
    output reg  [DATA_WIDTH-1:0]  rd_data1,
    input  wire [ADDR_WIDTH-1:0]  rd_addr2,
    output reg  [DATA_WIDTH-1:0]  rd_data2,
    
    // Subtractor related ports
    input  wire                   sub_en,
    input  wire [DATA_WIDTH-1:0]  minuend,
    input  wire [DATA_WIDTH-1:0]  subtrahend,
    output wire [DATA_WIDTH-1:0]  difference
);
    // Register file
    reg [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];
    
    // Borrowing subtractor signals
    wire [DATA_WIDTH:0] borrow;
    
    // Forwarding logic for read port 1
    always @(*) begin
        if (wr_en && (rd_addr1 == wr_addr) && (rd_addr1 != 0)) begin
            rd_data1 = wr_data;
        end
        else begin
            rd_data1 = regs[rd_addr1];
        end
    end
    
    // Forwarding logic for read port 2
    always @(*) begin
        if (wr_en && (rd_addr2 == wr_addr) && (rd_addr2 != 0)) begin
            rd_data2 = wr_data;
        end
        else begin
            rd_data2 = regs[rd_addr2];
        end
    end
    
    // Write operation with pipeline register
    integer i;
    reg [DATA_WIDTH-1:0] wr_data_reg;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
            wr_data_reg <= {DATA_WIDTH{1'b0}};
        end
        else if (wr_en && (wr_addr != 0)) begin
            wr_data_reg <= wr_data; // Pipeline register
            regs[wr_addr] <= wr_data_reg;
        end
    end
    
    // Borrowing subtractor implementation
    assign borrow[0] = 0;  // No initial borrow
    
    genvar j;
    generate
        for (j = 0; j < DATA_WIDTH; j = j + 1) begin: borrow_subtractor
            // Compute the current bit of difference
            assign difference[j] = minuend[j] ^ subtrahend[j] ^ borrow[j];
            
            // Compute the borrow for the next bit
            assign borrow[j+1] = (~minuend[j] & subtrahend[j]) | 
                                 (~minuend[j] & borrow[j]) | 
                                 (subtrahend[j] & borrow[j]);
        end
    endgenerate
endmodule