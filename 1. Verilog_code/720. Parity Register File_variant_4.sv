//SystemVerilog
module parity_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Write interface
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    
    // Read interface
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0]  rd_data,
    
    // Error detection
    output wire                   parity_error
);
    // Storage for data and parity
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] parity;  // One parity bit per register
    
    // Pipeline stage 1: Address decode and memory access
    reg [ADDR_WIDTH-1:0] rd_addr_stage1;
    reg [ADDR_WIDTH-1:0] wr_addr_stage1;
    reg wr_en_stage1;
    reg [DATA_WIDTH-1:0] wr_data_stage1;
    
    // Pipeline stage 2: Data read and parity calculation
    reg [DATA_WIDTH-1:0] rd_data_stage2;
    reg [DEPTH-1:0] parity_stage2;
    reg [ADDR_WIDTH-1:0] rd_addr_stage2;
    
    // Pipeline stage 3: Error detection
    reg [DATA_WIDTH-1:0] rd_data_stage3;
    reg [ADDR_WIDTH-1:0] rd_addr_stage3;
    reg parity_error_stage3;
    
    // Calculate parity for data (even parity: XOR of all bits should be 0)
    function bit calc_parity;
        input [DATA_WIDTH-1:0] data;
        begin
            calc_parity = ^data;  // XOR reduction
        end
    endfunction
    
    // Pipeline stage 1: Address decode and memory access
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
                parity[i] <= 1'b0;
            end
            rd_addr_stage1 <= {ADDR_WIDTH{1'b0}};
            wr_addr_stage1 <= {ADDR_WIDTH{1'b0}};
            wr_en_stage1 <= 1'b0;
            wr_data_stage1 <= {DATA_WIDTH{1'b0}};
        end
        else begin
            rd_addr_stage1 <= rd_addr;
            wr_addr_stage1 <= wr_addr;
            wr_en_stage1 <= wr_en;
            wr_data_stage1 <= wr_data;
            
            // Write operation with parity calculation
            if (wr_en) begin
                mem[wr_addr] <= wr_data;
                parity[wr_addr] <= calc_parity(wr_data);
            end
        end
    end
    
    // Pipeline stage 2: Data read and parity calculation
    always @(posedge clk) begin
        if (rst) begin
            rd_data_stage2 <= {DATA_WIDTH{1'b0}};
            parity_stage2 <= {DEPTH{1'b0}};
            rd_addr_stage2 <= {ADDR_WIDTH{1'b0}};
        end
        else begin
            rd_data_stage2 <= mem[rd_addr_stage1];
            parity_stage2 <= parity;
            rd_addr_stage2 <= rd_addr_stage1;
        end
    end
    
    // Pipeline stage 3: Error detection
    always @(posedge clk) begin
        if (rst) begin
            rd_data_stage3 <= {DATA_WIDTH{1'b0}};
            rd_addr_stage3 <= {ADDR_WIDTH{1'b0}};
            parity_error_stage3 <= 1'b0;
        end
        else begin
            rd_data_stage3 <= rd_data_stage2;
            rd_addr_stage3 <= rd_addr_stage2;
            parity_error_stage3 <= (calc_parity(rd_data_stage2) != parity_stage2[rd_addr_stage2]);
        end
    end
    
    // Output assignments
    assign rd_data = rd_data_stage3;
    assign parity_error = parity_error_stage3;
endmodule