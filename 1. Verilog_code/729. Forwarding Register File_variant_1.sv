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
    output reg  [DATA_WIDTH-1:0]  rd_data2
);
    // Register file
    reg [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];
    
    // Forwarding logic for read ports
    always @(*) begin
        // Default values
        rd_data1 = regs[rd_addr1];
        rd_data2 = regs[rd_addr2];

        // Forwarding logic for read port 1
        if (wr_en && (rd_addr1 == wr_addr) && (rd_addr1 != 0)) begin
            rd_data1 = wr_data;
        end
        
        // Forwarding logic for read port 2
        if (wr_en && (rd_addr2 == wr_addr) && (rd_addr2 != 0)) begin
            rd_data2 = wr_data;
        end
    end
    
    // Write operation
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (wr_en && (wr_addr != 0)) begin
            regs[wr_addr] <= wr_data;
        end
    end
endmodule