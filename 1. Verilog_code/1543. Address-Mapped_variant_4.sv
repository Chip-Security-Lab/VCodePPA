//SystemVerilog
// IEEE 1364-2005 Verilog standard
module address_shadow_reg #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter BASE_ADDR = 4'h0
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire read_en,
    output reg [WIDTH-1:0] data_out,
    output reg [WIDTH-1:0] shadow_data
);
    // Pipeline stage 1: Address decoding
    reg addr_match_stage1;
    reg shadow_addr_match_stage1;
    reg write_en_stage1;
    reg [WIDTH-1:0] data_in_stage1;
    
    // Pipeline stage 2: Control signals
    reg addr_match_stage2;
    reg shadow_addr_match_stage2;
    reg write_en_stage2;
    reg [WIDTH-1:0] data_in_stage2;
    
    // Pipeline stage 3: Intermediate data
    reg [WIDTH-1:0] data_out_stage3;
    
    // 优化的地址比较逻辑
    wire addr_match = (addr == BASE_ADDR);
    wire shadow_addr_match = (addr == (BASE_ADDR + 1'b1));
    
    // Stage 1: Address decoding pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_match_stage1 <= 1'b0;
            shadow_addr_match_stage1 <= 1'b0;
            write_en_stage1 <= 1'b0;
            data_in_stage1 <= {WIDTH{1'b0}};
        end
        else begin
            addr_match_stage1 <= addr_match;
            shadow_addr_match_stage1 <= shadow_addr_match;
            write_en_stage1 <= write_en;
            data_in_stage1 <= data_in;
        end
    end
    
    // Stage 2: Control signals pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_match_stage2 <= 1'b0;
            shadow_addr_match_stage2 <= 1'b0;
            write_en_stage2 <= 1'b0;
            data_in_stage2 <= {WIDTH{1'b0}};
        end
        else begin
            addr_match_stage2 <= addr_match_stage1;
            shadow_addr_match_stage2 <= shadow_addr_match_stage1;
            write_en_stage2 <= write_en_stage1;
            data_in_stage2 <= data_in_stage1;
        end
    end
    
    // Stage 3: Main register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else if (write_en_stage2 && addr_match_stage2)
            data_out <= data_in_stage2;
    end
    
    // Stage 3: Intermediate data for shadow register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out_stage3 <= {WIDTH{1'b0}};
        else
            data_out_stage3 <= data_out;
    end
    
    // Stage 4: Shadow register with address-mapped access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (write_en_stage2 && shadow_addr_match_stage2)
            shadow_data <= data_in_stage2;
        else if (write_en_stage2 && addr_match_stage2)
            shadow_data <= data_out_stage3;
    end
endmodule