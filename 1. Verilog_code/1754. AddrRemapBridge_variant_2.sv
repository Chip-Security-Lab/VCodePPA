//SystemVerilog
module AddrRemapBridge #(
    parameter BASE_ADDR = 32'h4000_0000,
    parameter OFFSET = 32'h1000
)(
    input clk, rst_n,
    input [31:0] orig_addr,
    output reg [31:0] remapped_addr,
    input addr_valid,
    output reg addr_ready
);
    // Stage 1 registers
    reg [31:0] addr_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [31:0] addr_stage2;
    reg valid_stage2;
    
    // Remap calculation split into stages
    wire [31:0] sub_result = orig_addr - BASE_ADDR;
    wire [31:0] remap_result = addr_stage1 + OFFSET;
    
    // Reset handling for stage 1
    always @(negedge rst_n) begin
        if (~rst_n) begin
            addr_stage1 <= 32'h0;
            valid_stage1 <= 1'b0;
        end
    end
    
    // Data processing for stage 1
    always @(posedge clk) begin
        if (rst_n) begin
            if (addr_valid && addr_ready) begin
                addr_stage1 <= sub_result;
                valid_stage1 <= 1'b1;
            end else if (valid_stage2) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Reset handling for stage 2
    always @(negedge rst_n) begin
        if (~rst_n) begin
            addr_stage2 <= 32'h0;
            valid_stage2 <= 1'b0;
            remapped_addr <= 32'h0;
        end
    end
    
    // Process valid_stage2 control logic
    always @(posedge clk) begin
        if (rst_n) begin
            if (valid_stage1) begin
                addr_stage2 <= remap_result;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Output stage remapping
    always @(posedge clk) begin
        if (rst_n && valid_stage2) begin
            remapped_addr <= addr_stage2;
        end
    end
    
    // Reset handling for ready signal
    always @(negedge rst_n) begin
        if (~rst_n) begin
            addr_ready <= 1'b0;
        end
    end
    
    // Ready signal logic - pipeline backpressure handling
    always @(posedge clk) begin
        if (rst_n) begin
            addr_ready <= !valid_stage1 || !valid_stage2;
        end
    end
endmodule