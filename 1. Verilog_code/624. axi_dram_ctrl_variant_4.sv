//SystemVerilog
module axi_dram_ctrl #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64
)(
    input wire clk,
    input wire rst_n,
    input wire axi_awvalid,
    input wire axi_wvalid,
    input wire [ADDR_WIDTH-1:0] axi_awaddr,
    input wire [DATA_WIDTH-1:0] axi_wdata,
    output reg axi_bready,
    output reg [DATA_WIDTH-1:0] axi_rdata
);

    // Memory and LUT declarations
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [7:0] lut_table [0:255];
    
    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] wdata_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [DATA_WIDTH-1:0] mem_data_stage2;
    reg [DATA_WIDTH-1:0] wdata_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [DATA_WIDTH-1:0] lut_result_stage3;
    reg valid_stage3;
    
    // Initialize LUT table
    integer i;
    initial begin
        for(i = 0; i < 256; i = i + 1) begin
            lut_table[i] = i;
        end
    end

    // Stage 1: Address and data capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            wdata_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= axi_awaddr;
            wdata_stage1 <= axi_wdata;
            valid_stage1 <= axi_awvalid && axi_wvalid;
        end
    end

    // Stage 2: Memory read and data forwarding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_data_stage2 <= 0;
            wdata_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            mem_data_stage2 <= memory[addr_stage1];
            wdata_stage2 <= wdata_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: LUT-based subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_result_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            lut_result_stage3 <= {DATA_WIDTH{1'b0}};
            for(i = 0; i < DATA_WIDTH/8; i = i + 1) begin
                lut_result_stage3[i*8 +: 8] <= lut_table[mem_data_stage2[i*8 +: 8]] - 
                                             lut_table[wdata_stage2[i*8 +: 8]];
            end
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Memory write and response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_bready <= 0;
            axi_rdata <= 0;
        end else begin
            if (valid_stage3) begin
                memory[addr_stage1] <= lut_result_stage3;
                axi_bready <= 1;
            end else begin
                axi_rdata <= memory[axi_awaddr];
                axi_bready <= 0;
            end
        end
    end

endmodule