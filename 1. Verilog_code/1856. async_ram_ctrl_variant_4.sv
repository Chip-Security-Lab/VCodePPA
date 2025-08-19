//SystemVerilog
module async_ram_ctrl #(
    parameter DATA_W = 8,
    parameter ADDR_W = 4,
    parameter DEPTH = 16
) (
    input wire wr_clk,
    input wire rd_clk,
    input wire rst,
    input wire [DATA_W-1:0] din,
    input wire [ADDR_W-1:0] waddr,
    input wire [ADDR_W-1:0] raddr,
    input wire we,
    output reg [DATA_W-1:0] dout
);

    // Memory array
    reg [DATA_W-1:0] mem [0:DEPTH-1];
    
    // Write path registers
    reg [DATA_W-1:0] wr_data_reg;
    reg [ADDR_W-1:0] wr_addr_reg;
    reg wr_en_reg;
    
    // Read path registers
    reg [ADDR_W-1:0] rd_addr_reg;
    reg [DATA_W-1:0] rd_data_reg;
    
    // Write path pipeline
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_data_reg <= {DATA_W{1'b0}};
            wr_addr_reg <= {ADDR_W{1'b0}};
            wr_en_reg <= 1'b0;
        end else begin
            wr_data_reg <= din;
            wr_addr_reg <= waddr;
            wr_en_reg <= we;
        end
    end
    
    // Memory write operation
    always @(posedge wr_clk) begin
        if (wr_en_reg) begin
            mem[wr_addr_reg] <= wr_data_reg;
        end
    end
    
    // Read path pipeline
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_addr_reg <= {ADDR_W{1'b0}};
            rd_data_reg <= {DATA_W{1'b0}};
        end else begin
            rd_addr_reg <= raddr;
            rd_data_reg <= mem[rd_addr_reg];
        end
    end
    
    // Output register
    always @(posedge rd_clk) begin
        dout <= rd_data_reg;
    end

endmodule