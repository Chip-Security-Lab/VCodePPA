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
    
    // Forwarding logic for read port 1
    always @(*) begin
        if (wr_en && (rd_addr1 == wr_addr) && (rd_addr1 != 0)) begin
            // Forward the write data if reading the same register that's being written
            rd_data1 = wr_data;
        end
        else begin
            // Normal read from register file
            rd_data1 = regs[rd_addr1];
        end
    end
    
    // Forwarding logic for read port 2
    always @(*) begin
        if (wr_en && (rd_addr2 == wr_addr) && (rd_addr2 != 0)) begin
            // Forward the write data if reading the same register that's being written
            rd_data2 = wr_data;
        end
        else begin
            // Normal read from register file
            rd_data2 = regs[rd_addr2];
        end
    end
    
    // Write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (wr_en && (wr_addr != 0)) begin
            // Register 0 is hardwired to zero in many architectures
            regs[wr_addr] <= wr_data;
        end
    end
endmodule