module separate_addr_regfile #(
    parameter DATA_W = 32,
    parameter WR_ADDR_W = 4,   // Write address width
    parameter RD_ADDR_W = 5    // Read address width (can address more locations)
)(
    input  wire                  clk,
    input  wire                  rst_n,
    
    // Write port (fewer addresses)
    input  wire                  wr_en,
    input  wire [WR_ADDR_W-1:0]  wr_addr,
    input  wire [DATA_W-1:0]     wr_data,
    
    // Read port (more addresses)
    input  wire [RD_ADDR_W-1:0]  rd_addr,
    output wire [DATA_W-1:0]     rd_data
);
    // Storage - sized by the larger address space
    reg [DATA_W-1:0] registers [0:(2**RD_ADDR_W)-1];
    
    // Asynchronous read
    assign rd_data = registers[rd_addr];
    
    // Write operation (note that wr_addr only covers a subset of the registers)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < (2**RD_ADDR_W); i = i + 1) begin
                registers[i] <= {DATA_W{1'b0}};
            end
        end
        else if (wr_en) begin
            // Write address is extended to match the full register address space
            registers[{{(RD_ADDR_W-WR_ADDR_W){1'b0}}, wr_addr}] <= wr_data;
        end
    end
endmodule
