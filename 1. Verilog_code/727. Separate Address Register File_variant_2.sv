//SystemVerilog
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
    output reg  [DATA_W-1:0]     rd_data
);
    // Storage - sized by the larger address space
    reg [DATA_W-1:0] registers [0:(2**RD_ADDR_W)-1];
    
    // Pipeline stages for read operation
    reg [RD_ADDR_W-1:0] rd_addr_stage1;
    reg [DATA_W-1:0] rd_data_stage1;
    reg [DATA_W-1:0] rd_data_stage2;
    
    // Write operation pipeline signals
    reg wr_en_stage1;
    reg [WR_ADDR_W-1:0] wr_addr_stage1;
    reg [DATA_W-1:0] wr_data_stage1;
    reg [(RD_ADDR_W-WR_ADDR_W)+WR_ADDR_W-1:0] wr_full_addr;
    
    // Stage 1: Capture inputs and calculate addresses
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr_stage1 <= {RD_ADDR_W{1'b0}};
            wr_en_stage1 <= 1'b0;
            wr_addr_stage1 <= {WR_ADDR_W{1'b0}};
            wr_data_stage1 <= {DATA_W{1'b0}};
            wr_full_addr <= {RD_ADDR_W{1'b0}};
        end
        else begin
            rd_addr_stage1 <= rd_addr;
            wr_en_stage1 <= wr_en;
            wr_addr_stage1 <= wr_addr;
            wr_data_stage1 <= wr_data;
            wr_full_addr <= {{(RD_ADDR_W-WR_ADDR_W){1'b0}}, wr_addr};
        end
    end
    
    // Stage 2: Memory access
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            for (i = 0; i < (2**RD_ADDR_W); i = i + 1) begin
                registers[i] <= {DATA_W{1'b0}};
            end
            rd_data_stage1 <= {DATA_W{1'b0}};
        end
        else begin
            // Write operation
            if (wr_en_stage1) begin
                registers[wr_full_addr] <= wr_data_stage1;
            end
            
            // Read operation - first stage
            rd_data_stage1 <= registers[rd_addr_stage1];
        end
    end
    
    // Stage 3: Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data_stage2 <= {DATA_W{1'b0}};
            rd_data <= {DATA_W{1'b0}};
        end
        else begin
            rd_data_stage2 <= rd_data_stage1;
            rd_data <= rd_data_stage2;
        end
    end
    
endmodule