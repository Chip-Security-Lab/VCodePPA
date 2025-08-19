//SystemVerilog
module regfile_2r1w_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] rd_addr0,
    input wire [ADDR_WIDTH-1:0] rd_addr1,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data0,
    output reg [DATA_WIDTH-1:0] rd_data1
);
    // Memory array declaration
    reg [DATA_WIDTH-1:0] mem_array [0:DEPTH-1];
    
    // Pipeline registers for read addresses
    reg [ADDR_WIDTH-1:0] rd_addr0_pipe;
    reg [ADDR_WIDTH-1:0] rd_addr1_pipe;
    
    // Pipeline registers for read data
    reg [DATA_WIDTH-1:0] rd_data0_pre;
    reg [DATA_WIDTH-1:0] rd_data1_pre;
    
    // Write forwarding detection signals
    reg wr_rd0_hazard;
    reg wr_rd1_hazard;
    
    // Write data pipeline register
    reg [DATA_WIDTH-1:0] wr_data_pipe;
    reg [ADDR_WIDTH-1:0] wr_addr_pipe;
    reg wr_en_pipe;
    
    // Reset and initialization logic
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem_array[i] <= {DATA_WIDTH{1'b0}};
            end
            rd_addr0_pipe <= {ADDR_WIDTH{1'b0}};
            rd_addr1_pipe <= {ADDR_WIDTH{1'b0}};
            wr_data_pipe <= {DATA_WIDTH{1'b0}};
            wr_addr_pipe <= {ADDR_WIDTH{1'b0}};
            wr_en_pipe <= 1'b0;
        end else begin
            // Pipeline stage 1: Register inputs
            rd_addr0_pipe <= rd_addr0;
            rd_addr1_pipe <= rd_addr1;
            wr_data_pipe <= wr_data;
            wr_addr_pipe <= wr_addr;
            wr_en_pipe <= wr_en;
        end
    end
    
    // Write operation - stage 2
    always @(posedge clk) begin
        if (rst_n && wr_en_pipe) begin
            mem_array[wr_addr_pipe] <= wr_data_pipe;
        end
    end
    
    // Write-read hazard detection
    always @(posedge clk) begin
        if (rst_n) begin
            wr_rd0_hazard <= wr_en && (wr_addr == rd_addr0);
            wr_rd1_hazard <= wr_en && (wr_addr == rd_addr1);
        end else begin
            wr_rd0_hazard <= 1'b0;
            wr_rd1_hazard <= 1'b0;
        end
    end
    
    // Read operation with data path isolation
    always @(posedge clk) begin
        if (rst_n) begin
            // Read port 0 - with forwarding logic
            if (wr_rd0_hazard) begin
                rd_data0_pre <= wr_data_pipe;
            end else begin
                rd_data0_pre <= mem_array[rd_addr0_pipe];
            end
            
            // Read port 1 - with forwarding logic
            if (wr_rd1_hazard) begin
                rd_data1_pre <= wr_data_pipe;
            end else begin
                rd_data1_pre <= mem_array[rd_addr1_pipe];
            end
            
            // Final output stage
            rd_data0 <= rd_data0_pre;
            rd_data1 <= rd_data1_pre;
        end
    end
endmodule