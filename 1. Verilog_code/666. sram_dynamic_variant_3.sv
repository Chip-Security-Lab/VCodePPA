//SystemVerilog
module sram_dynamic #(
    parameter MAX_DEPTH = 1024,
    parameter DW = 32
)(
    input clk,
    input rst_n,
    input [31:0] config_word,
    input we,
    input [31:0] addr,
    input [DW-1:0] din,
    input valid_in,
    output [DW-1:0] dout,
    output valid_out
);

// Pipeline stage 1
reg [15:0] configured_width_stage1, actual_width_stage1;
reg [15:0] configured_depth_stage1, actual_depth_stage1;
reg [31:0] addr_stage1;
reg [DW-1:0] din_stage1;
reg we_stage1;
reg valid_stage1;
reg addr_valid_stage1;

// Pipeline stage 2
reg [15:0] actual_width_stage2;
reg [31:0] addr_stage2;
reg [DW-1:0] din_stage2;
reg we_stage2;
reg valid_stage2;
reg addr_valid_stage2;

// Pipeline stage 3
reg [DW-1:0] read_data_stage3;
reg valid_stage3;

// Memory array
reg [DW-1:0] mem [0:MAX_DEPTH-1];

// Intermediate pipeline registers for critical path cutting
reg [DW-1:0] mask_partial_reg;
reg [DW-1:0] din_masked_reg;
reg [DW-1:0] mem_data_reg;
reg [DW-1:0] write_data_reg;
reg [DW-1:0] read_data_intermediate;

// Stage 1: Configuration analysis
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        configured_width_stage1 <= 0;
        configured_depth_stage1 <= 0;
        actual_width_stage1 <= 0;
        actual_depth_stage1 <= 0;
        addr_stage1 <= 0;
        din_stage1 <= 0;
        we_stage1 <= 0;
        valid_stage1 <= 0;
        addr_valid_stage1 <= 0;
    end else begin
        configured_width_stage1 <= config_word[15:0];
        configured_depth_stage1 <= config_word[31:16];
        
        actual_width_stage1 <= (config_word[15:0] == 0) ? DW : 
                              (config_word[15:0] > DW) ? DW : config_word[15:0];
                           
        actual_depth_stage1 <= (config_word[31:16] == 0) ? MAX_DEPTH : 
                              (config_word[31:16] > MAX_DEPTH) ? MAX_DEPTH : config_word[31:16];
        
        addr_stage1 <= addr;
        din_stage1 <= din;
        we_stage1 <= we;
        valid_stage1 <= valid_in;
        
        addr_valid_stage1 <= (addr < ((config_word[31:16] == 0) ? MAX_DEPTH : 
                            (config_word[31:16] > MAX_DEPTH) ? MAX_DEPTH : config_word[31:16]));
    end
end

// Stage 1.5: Critical path cutting for mask and data preparation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mask_partial_reg <= 0;
        din_masked_reg <= 0;
    end else begin
        mask_partial_reg <= (1 << actual_width_stage1) - 1;
        din_masked_reg <= din_stage1 & ((1 << actual_width_stage1) - 1);
    end
end

// Stage 2: Memory access preparation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        actual_width_stage2 <= 0;
        addr_stage2 <= 0;
        din_stage2 <= 0;
        we_stage2 <= 0;
        valid_stage2 <= 0;
        addr_valid_stage2 <= 0;
        mem_data_reg <= 0;
        write_data_reg <= 0;
    end else begin
        actual_width_stage2 <= actual_width_stage1;
        addr_stage2 <= addr_stage1;
        din_stage2 <= din_stage1;
        we_stage2 <= we_stage1;
        valid_stage2 <= valid_stage1;
        addr_valid_stage2 <= addr_valid_stage1;
        
        // Register memory data to cut critical path
        mem_data_reg <= mem[addr_stage1];
        
        // Register write data calculation to cut critical path
        write_data_reg <= (actual_width_stage1 == DW) ? din_stage1 :
                          (mem_data_reg & ~mask_partial_reg) | din_masked_reg;
        
        if (we_stage1 && addr_valid_stage1 && valid_stage1) begin
            mem[addr_stage1] <= write_data_reg;
        end
    end
end

// Stage 2.5: Critical path cutting for read data preparation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_data_intermediate <= 0;
    end else begin
        if (addr_valid_stage2 && valid_stage2) begin
            if (actual_width_stage2 == DW) begin
                read_data_intermediate <= mem[addr_stage2];
            end else begin
                read_data_intermediate <= mem[addr_stage2] & ((1 << actual_width_stage2) - 1);
            end
        end else begin
            read_data_intermediate <= 0;
        end
    end
end

// Stage 3: Memory access execution
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        read_data_stage3 <= 0;
        valid_stage3 <= 0;
    end else begin
        valid_stage3 <= valid_stage2;
        read_data_stage3 <= read_data_intermediate;
    end
end

assign dout = read_data_stage3;
assign valid_out = valid_stage3;

endmodule