//SystemVerilog
module addr_trans_bridge #(parameter DWIDTH=32, AWIDTH=16) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [AWIDTH-1:0] dst_addr,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    reg [AWIDTH-1:0] base_addr = 'h1000;
    reg [AWIDTH-1:0] limit_addr = 'h2000;
    
    // LUT-based subtractor implementation
    reg [7:0] lut_diff[255:0];
    reg [7:0] high_bits_result;
    reg [7:0] low_bits_result;
    reg borrow;
    
    // Initialize LUT
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut_diff[i] = i - (base_addr[7:0]);
        end
    end
    
    // Pre-compute borrow flag
    wire borrow_flag = src_addr[7:0] < base_addr[7:0];
    
    // Pipeline registers
    reg [AWIDTH-1:0] src_addr_reg;
    reg [DWIDTH-1:0] src_data_reg;
    reg valid_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            dst_valid <= 0;
            src_ready <= 1;
            dst_addr <= 0;
            dst_data <= 0;
            src_addr_reg <= 0;
            src_data_reg <= 0;
            valid_reg <= 0;
        end else begin
            // Stage 1: Register inputs
            if (src_valid && src_ready) begin
                src_addr_reg <= src_addr;
                src_data_reg <= src_data;
                valid_reg <= 1;
                src_ready <= 0;
            end
            
            // Stage 2: Compute subtraction
            if (valid_reg) begin
                if (src_addr_reg >= base_addr && src_addr_reg < limit_addr) begin
                    low_bits_result = lut_diff[src_addr_reg[7:0]];
                    
                    if (AWIDTH > 8) begin
                        high_bits_result = src_addr_reg[AWIDTH-1:8] - base_addr[AWIDTH-1:8] - borrow_flag;
                        dst_addr <= {high_bits_result, low_bits_result};
                    end else begin
                        dst_addr <= low_bits_result;
                    end
                    
                    dst_data <= src_data_reg;
                    dst_valid <= 1;
                end
                valid_reg <= 0;
            end
            
            if (dst_valid && dst_ready) begin
                dst_valid <= 0;
                src_ready <= 1;
            end
        end
    end
endmodule